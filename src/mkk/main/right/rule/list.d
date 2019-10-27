module mkk.main.right.rule.list;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getRightRuleList)(`right.rule.list`);
	MainService.JSON_RPCRouter.join!(readRightRule)(`right.rule.read`);

	MainService.pageRouter.joinWebFormAPI!(getRightRuleList)("/api/right/rule/list");
	MainService.pageRouter.joinWebFormAPI!(readRightRule)("/api/right/rule/read");
}

static immutable rightRuleRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "name",
	size_t[], "children",
	ubyte, "relation"
)();

Tuple!(
	IBaseRecordSet, `ruleList`,
	Navigation, `nav`
)
getRightRuleList(HTTPContext ctx, string name, Navigation nav)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	size_t pohodCount = getAuthDB().queryParams(
		`select count(1) from access_rule`
	).getScalar!size_t();

	nav.normalize(pohodCount);

	return typeof(return)(
		getAuthDB().queryParams(`
	select
	num,
	name,
	children,
	relation
	from access_rule a_rule
	where a_rule.name ilike '%' || coalesce($1::text, '') || '%'
	order by a_rule.name
	offset $2::integer limit $3::integer
	`, name, nav.offset, nav.pageSize).getRecordSet(rightRuleRecFormat), nav);
}


Tuple!(IBaseRecord, `ruleRec`)
readRightRule(HTTPContext ctx, Optional!size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);

	if( num.isNull ) {
		return typeof(return)(makeMemoryRecord(rightRuleRecFormat));
	}

	return typeof(return)(
		getAuthDB().queryParams(`
	select
	num,
	name,
	children,
	relation
	from access_rule a_rule
	where a_rule.num = $1::integer
	`, num).getRecord(rightRuleRecFormat));
}