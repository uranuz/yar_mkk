module mkk_site.main_service.right_object_list;

import mkk_site.main_service.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getObjectList)(`right.objectList`);
	MainService.JSON_RPCRouter.join!(getObjectRightList)(`right.objectRightList`);
}

static immutable rightObjectRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "name",
	string, "description",
	size_t, "parent_num"
)();

auto getObjectList(HTTPContext ctx)
{
	import std.exception: enforce;
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	return getAuthDB().query(`
	select num, name, description, parent_num
	from access_object
	`).getRecordSet(rightObjectRecFormat);
}

static immutable objRightsRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "access_kind",
	string, "role_name",
	string, "rule_name"
)();

auto getObjectRightList(HTTPContext ctx, size_t num)
{
	import std.exception: enforce;
	import std.conv: text;
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	return getAuthDB().query(`
	select
		rgh.num,
		rgh.kind "access_kind",
		a_role.name "role_name",
		a_rule.name "rule_name"
	from access_right rgh
	left join access_role a_role
		on a_role.num = rgh.role_num
	left join access_rule a_rule
		on a_rule.num = rgh.rule_num
	where rgh.object_num = ` ~ num.text ~ `
	`).getRecordSet(rightObjectRecFormat);
}