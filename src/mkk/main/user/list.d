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
	bool, "is_confirmed"
)();

Tuple!(IBaseRecordSet, `userList`) userList(HTTPContext ctx)
{
	return typeof(return)(getAuthDB().queryParams(`
		select
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
					a_role.name != $1::text
			) is_confirmed
		from site_user su
		order by su.name, su.login, su.num
		`, NEW_USER_ROLE).getRecordSet(userListRecFormat));
}

