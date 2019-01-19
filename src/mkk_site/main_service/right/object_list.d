module mkk_site.main_service.right.object_list;

import mkk_site.main_service.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getObjectList)(`right.objectList`);
	MainService.JSON_RPCRouter.join!(getObjectRightList)(`right.objectRightList`);

	MainService.pageRouter.joinWebFormAPI!(getObjectList)("/api/right/object/list");
	MainService.pageRouter.joinWebFormAPI!(getObjectRightList)("/api/right/object/right/list");
}

static immutable rightObjectRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "name",
	string, "description",
	size_t, "parentNum"
)();

Tuple!(IBaseRecordSet, `objectList`)
getObjectList(HTTPContext ctx)
{
	import std.exception: enforce;

	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	return typeof(return)(getAuthDB().query(`
	select num, name, description, parent_num
	from access_object
	`).getRecordSet(rightObjectRecFormat));
}

static immutable objRightRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "accessKind",
	string, "roleName",
	string, "ruleName",
	bool, "inheritance"
)();

Tuple!(IBaseRecordSet, `objectRightList`)
getObjectRightList(HTTPContext ctx, size_t num)
{
	import std.exception: enforce;
	import std.conv: text;
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	return typeof(return)(getAuthDB().query(`
	select
		rgh.num,
		rgh."access_kind" "accessKind",
		a_role.name "roleName",
		a_rule.name "ruleName",
		rgh.inheritance
	from access_right rgh
	left join access_role a_role
		on a_role.num = rgh.role_num
	left join access_rule a_rule
		on a_rule.num = rgh.rule_num
	where rgh.object_num = ` ~ num.text ~ `
	`).getRecordSet(objRightRecFormat));
}