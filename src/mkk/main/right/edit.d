module mkk.main.right.right.edit;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editRight)(`right.edit`);
	MainService.JSON_RPCRouter.join!(deleteRight)(`right.delete`);

	MainService.pageRouter.joinWebFormAPI!(editRight)("/api/right/edit");
}

struct RightRuleData
{
	Optional!size_t num;

@RightObjAttr(`right.object.right`)
@RightObjAttr() {
	@DBField(`object_num`) Undefable!size_t objectNum;
	@DBField(`rule_num`) Undefable!size_t ruleNum;
	@DBField(`access_kind`) Undefable!string accessKind;
	@DBField(`role_num`) Undefable!size_t roleNum;
	@DBField(`inheritance`) Undefable!bool inheritance;
}

}


Tuple!(size_t, `num`)
editRight(HTTPContext ctx, RightRuleData record)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);
	//checkStructEditRights(record, ctx);

	enforce(
		record.objectNum.isSet
		&& record.roleNum.isSet
		&& record.ruleNum.isSet,
		`Заполнены не все обязательные поля`);
	string[] fieldNames;
	string[] fieldValues;

	mixin(WalkFields!(`record`, q{
		fieldNames ~= dbFieldName;
		fieldValues ~= field.toPGString();
	}));

	typeof(return) res;
	if( fieldNames.empty ) {
		return res;
	}

	ctx.service.log.info("Формирование и выполнение запроса к БД", "Изменение права доступа");
	res.num = getAuthDB().insertOrUpdateTableByNum(`access_right`, fieldNames, fieldValues, record.num);
	ctx.service.log.info("Выполнение запроса к БД завершено", "Изменение права доступа");

	return res;
}


void deleteRight(HTTPContext ctx, size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);

	ctx.service.log.info("Формирование и выполнение запроса к БД", "Удаление права доступа");
	getAuthDB().queryParams(`delete from access_right a_right where a_right.num = $1::integer`, num);
	ctx.service.log.info("Выполнение запроса к БД завершено", "Удаление права доступа");
}