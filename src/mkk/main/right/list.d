module mkk.main.right.list;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getRightList)(`right.list`);

	MainService.pageRouter.joinWebFormAPI!(getRightList)("/api/right/list");
}

static immutable rightQueryBase = `
select
	rgh.num,
	a_obj.num "objectNum",
	a_role.num "roleNum",
	a_rule.num "ruleNum",
	rgh."access_kind" "accessKind",
	a_obj.name "objectName",
	a_role.name "roleName",
	a_rule.name "ruleName",
	rgh.inheritance
from access_right rgh
join access_object a_obj
	on a_obj.num = rgh.object_num
left join access_role a_role
	on a_role.num = rgh.role_num
left join access_rule a_rule
	on a_rule.num = rgh.rule_num
%s`;

static immutable objRightRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	size_t, "objectNum",
	size_t, "roleNum",
	size_t, "ruleNum",
	string, "accessKind",
	string, "objectName",
	string, "roleName",
	string, "ruleName",
	bool, "inheritance"
)();

Tuple!(IBaseRecordSet, `rightList`)
getRightList(HTTPContext ctx, Optional!size_t num)
{
	import std.format: format;

	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);
	return typeof(return)(
		getAuthDB().queryParams(
			rightQueryBase.format(
`where rgh.object_num = $1::integer
order by a_obj.name, rgh.access_kind`), num
	).getRecordSet(objRightRecFormat));
}