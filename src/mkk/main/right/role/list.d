module mkk.main.right.role.list;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getRightRoleList)(`right.role.list`);
	MainService.JSON_RPCRouter.join!(readRole)(`right.role.read`);

	MainService.pageRouter.joinWebFormAPI!(getRightRoleList)("/api/right/role/list");
	MainService.pageRouter.joinWebFormAPI!(readRole)("/api/right/role/read");
}

static immutable rightRoleRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "name",
	string, "description"
)();

Tuple!(
	IBaseRecordSet, `roleList`,
	Navigation, `nav`
)
getRightRoleList(HTTPContext ctx, string name, Navigation nav)
{
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	size_t roleCount = getAuthDB().queryParams(
		`select count(1) from access_role`
	).getScalar!size_t();

	nav.normalize(roleCount);

	return typeof(return)(
		getAuthDB().queryParams(`
	select
	num,
	name,
	description
	from access_role a_role
	where a_role.name ilike '%' || coalesce($1::text, '') || '%'
	order by a_role.name
	offset $2::integer limit $3::integer
	`, name, nav.offset, nav.pageSize).getRecordSet(rightRoleRecFormat), nav);
}

Tuple!(IBaseRecord, `role`)
readRole(HTTPContext ctx, Optional!size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);

	if( num.isNull ) {
		return typeof(return)(makeMemoryRecord(rightRoleRecFormat));
	}

	return typeof(return)(
		getAuthDB().queryParams(`
	select
	num,
	name,
	description
	from access_role a_role
	where a_role.num = $1
	`, num).getRecord(rightRoleRecFormat));
}