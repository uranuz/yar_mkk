module mkk.main.user.list;
import mkk.main.devkit;

import mkk.main.user.consts: NEW_USER_ROLE;

shared static this()
{
	MainService.JSON_RPCRouter.join!(userList)(`user.list`);

	MainService.pageRouter.joinWebFormAPI!(userList)("/api/user/list");
}

import std.datetime: DateTime;

/// Формат записи для списка пользователей сайта
static immutable userListRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "name",
	string, "login",
	DateTime, "reg_timestamp",
	bool, "is_email_confirmed",
	bool, "is_blocked",
	bool, "is_confirmed",
	string, "email"
)();

static immutable userListQueryBase = `
select
	%s
from site_user su
where
	su.name ilike '%%' || coalesce($1::text, '') || '%%'
%s
`;

import std.stdio;

Tuple!(
	IBaseRecordSet, `userList`,
	Navigation, `nav`
)
userList(HTTPContext ctx, string name, Navigation nav)
{
	import std.format: format;

	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию
	
	size_t recordCount = getAuthDB().queryParams(
		userListQueryBase.format(`count(1)`, ``), name
	).getScalar!size_t();

	nav.normalize(recordCount);

	// Проверяем права на отображение пароля
	bool showEmail = ctx.rights.hasRight(`user.item.email`, `read`);

	return typeof(return)(
		getAuthDB().queryParams(
			userListQueryBase.format(`
			num,
			name,
			login,
			reg_timestamp,
			is_email_confirmed,
			is_blocked,
			exists(
				select 1
				from user_access_role uar
				join access_role a_role
					on a_role.num = uar.role_num
				where
					uar.user_num = su.num
					and
					a_role.name != $4::text
			) is_confirmed,
			(case when $5::boolean is true
				then su."email"
				else null::text
			end) email
			`,
			`order by su.name, su.login, su.num
			offset $2 limit $3
			`),
			name, nav.offset, nav.pageSize, NEW_USER_ROLE, showEmail
		).getRecordSet(userListRecFormat),
		nav
	);
}

