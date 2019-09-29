module mkk.main.right.role.edit;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editRule)(`right.role.edit`);
	MainService.JSON_RPCRouter.join!(deleteRule)(`right.role.delete`);

	MainService.pageRouter.joinWebFormAPI!(editRule)("/api/right/role/edit");
}

struct RightRoleData
{
	Optional!size_t num;

@RightObjAttr(`right.role.item`)
@RightObjAttr() {
	@DBField(`name`) Undefable!string name;
	@DBField(`description`) Undefable!string description;
}

}

Tuple!(size_t, `num`)
editRule(HTTPContext ctx, RightRoleData record)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);
	//checkStructEditRights(record, ctx);
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

	MainService.loger.info("Формирование и выполнение запроса к БД", "Изменение роли доступа");
	res.num = getAuthDB().insertOrUpdateTableByNum(`access_role`, fieldNames, fieldValues, record.num);
	MainService.loger.info("Выполнение запроса к БД завершено", "Изменение роли доступа");

	return res;
}

void deleteRule(HTTPContext ctx, size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);

	MainService.loger.info("Формирование и выполнение запроса к БД", "Удаление роли доступа");
	getAuthDB().queryParams(`delete from access_role a_role where a_role.num = $1::integer`, num);
	MainService.loger.info("Выполнение запроса к БД завершено", "Удаление роли доступа");
}
