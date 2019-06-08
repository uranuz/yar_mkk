module mkk.main.right.rule_edit;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editRule)(`right.rule.edit`);
	MainService.JSON_RPCRouter.join!(deleteRule)(`right.rule.delete`);

	MainService.pageRouter.joinWebFormAPI!(editRule)("/api/right/rule/edit");
}

struct RightRuleData
{
	Optional!size_t num;

@RightObjAttr(`right.rule.item`)
@RightObjAttr() {
	@DBField(`name`) Undefable!string name;
}

}

Tuple!(size_t, `num`)
editRule(HTTPContext ctx, RightRuleData record)
{
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	//checkStructEditRights(record, ctx);
	string[] fieldNames;
	string[] fieldValues;

	mixin(WalkFields!(`record`, q{
		fieldNames ~= fieldName;
		fieldValues ~= field.toPGString();
	}));

	typeof(return) res;
	if( fieldNames.empty ) {
		return res;
	}

	MainService.loger.info("Формирование и выполнение запроса к БД", "Изменение правила доступа");
	res.num = getAuthDB().insertOrUpdateTableByNum(`access_rule`, fieldNames, fieldValues, record.num);
	MainService.loger.info("Выполнение запроса к БД завершено", "Изменение правила доступа");

	return res;
}

void deleteRule(HTTPContext ctx, size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);

	MainService.loger.info("Формирование и выполнение запроса к БД", "Удаление правила доступа");
	getAuthDB().queryParams(`delete from access_rule a_rule where a_rule.num = $1::integer`, num);
	MainService.loger.info("Выполнение запроса к БД завершено", "Удаление правила доступа");
}
