module mkk.main.right.object.edit;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(readObject)(`right.object.edit`);

	MainService.pageRouter.joinWebFormAPI!(readObject)("/api/right/object/edit");
}

struct RightObjData
{
	Optional!size_t num;

@RightObjAttr(`right.object.item`)
@RightObjAttr() {
	@DBField(`name`) Undefable!string name;
	@DBField(`description`) Undefable!string description;
	@DBField(`parent_num`) Undefable!size_t parentNum;
}

}


Tuple!(size_t, `num`)
readObject(HTTPContext ctx, RightObjData record)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);
	checkStructEditRights(record, ctx);
	string[] fieldNames;
	string[] fieldValues;

	mixin(WalkFields!(`record`, q{
		fieldNames ~= dbFieldName;
		fieldValues ~= field.toPGString();
	}));

	auto res = typeof(return)(record.num);
	if( fieldNames.empty ) {
		return res;
	}

	MainService.loger.info("Формирование и выполнение запроса к БД", "Изменение объекта доступа");
	res.num = getCommonDB().insertOrUpdateTableByNum(`access_object`, fieldNames, fieldValues, record.num);
	MainService.loger.info("Выполнение запроса к БД завершено", "Изменение объекта доступа");

	return res;
}
