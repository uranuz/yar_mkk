module mkk.main.tourist.edit;

import mkk.main.devkit;

import mkk.main.tourist.model;

import mkk.history.client;
import mkk.history.common;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editTourist)(`tourist.edit`);
	MainService.JSON_RPCRouter.join!(touristDelete)(`tourist.delete`);

	MainService.pageRouter.joinWebFormAPI!(editTourist)("/api/tourist/edit/results");
}

import std.typecons: Tuple;

Tuple!(Optional!size_t, `touristNum`)
editTourist(
	HTTPContext ctx,
	TouristDataToWrite record
) {
	import std.meta: AliasSeq, staticMap;
	import std.algorithm: canFind, countUntil;
	import std.conv: to, text, ConvException;
	import std.typecons: tuple;
	import mkk.main.enums;
	import std.json: JSONValue;
	import std.exception: enforce;
	import std.range: empty;

	enforce(ctx.rights.hasRight(`tourist.item`, `edit`), `Недостаточно прав для редактирования туриста!`);
	checkStructEditRights(record, ctx); // Проверка прав

	string[] fieldNames; // имена полей для записи
	string[] fieldValues; // значения полей для записи

	alias TouristEnums = AliasSeq!(
		tuple("sportsCategory", sportsCategory),
		tuple("refereeCategory", refereeCategory)
	);
	enum string GetFieldName(alias E) = E[0];
	enum enumFieldNames = [staticMap!(GetFieldName, TouristEnums)];

	mixin(WalkFields!(`record`, q{
		// Проверка данных
		static if( enumFieldNames.canFind(fieldName) )
		{
			auto enumFormat = TouristEnums[enumFieldNames.countUntil(fieldName)][1];
			enforce!ConvException(
				!field.isSet || field.value in enumFormat,
				`Выражение "` ~ field.value.text ~ `" не является значением типа "` ~ fieldName ~ `"!!!`);
		}

		static if( fieldName == "birthMonth" )
		{
			fieldNames ~= dbFieldName;
			enforce(
				!field.isSet || (1 <= field && field <= 12),
				"Номер месяца должен быть числом от 1 до 12!");
			enforce(
				!field.isSet || (1 <= field && field <= 31),
				"День месяца должен быть числом от 1 до 31!");

			if( record.birthDay.isNull && record.birthMonth.isNull ) {
				fieldValues ~= "NULL";
			} else {
				fieldValues ~= (record.birthDay.isSet? record.birthDay.text: null)
					~ `.` ~ (record.birthMonth.isSet? record.birthMonth.text: null);
			}
		} else static if( fieldName == "birthDay" ) {
			// Ничего не делаем - специально оставлено пусто
		} else {
			fieldNames ~= dbFieldName;
			fieldValues ~= field.toPGString();
		}
	}));

	auto res = typeof(return)(record.num);
	if( fieldNames.empty ) {
		return res;
	}

	enforce("userNum" in ctx.user.data, "Не удаётся определить идентификатор пользователя");
	//Запись автора последних изменений и даты этих изменений
	fieldNames ~= "last_editor_num";
	fieldValues ~= ctx.user.data["userNum"];

	// Это постоянные, которые НЕ экранируются в запросе
	string[] safeFieldNames = ["last_edit_timestamp"];
	string[] safeFieldValues = ["current_timestamp"];

	if( !record.num.isSet )
	{
		// При создании записи сохраняем - кто и когда ее создал
		fieldNames ~= "registrator_num";
		fieldValues ~= ctx.user.data["userNum"];

		safeFieldNames ~= "reg_timestamp";
		safeFieldValues ~= "current_timestamp";
	}

	// Создадим транзакцию для записи информации
	import webtank.db.transaction: makeTransaction;
	auto trans = getCommonDB().makeTransaction();
	scope(failure) trans.rollback();
	scope(success) trans.commit();

	res.touristNum = getCommonDB().insertOrUpdateTableByNum(
		`tourist`, fieldNames, fieldValues, record.num, safeFieldNames, safeFieldValues);
	if( !res.touristNum.isSet ) {
		return res;
	}

	auto fullRec = getCommonDB().query(
		touristFullQuery ~ ` where num = ` ~ res.touristNum.text
	).getRecord(touristFullFormat);

	JSONValue jFullData;
	foreach( field; touristFullFormat.names ) {
		jFullData[field] = fullRec.getField(field).getStdJSONValue(fullRec.recordIndex);
	}
	
	// Сохранение истории действий и изменений
	import webtank.common.std_json.to: toStdJSON;
	record.dbSerializeMode = true; // Пишем в JSON имена полей как в БД
	HistoryRecordData historyData = {
		tableName: `tourist`,
		recordNum: res.touristNum,
		data: jFullData,
		recordKind: (record.num.isSet? HistoryRecordKind.Update: HistoryRecordKind.Insert)
	};
	sendToHistory(ctx, (record.num.isSet? `Редактирование туриста`: `Добавление туриста`), historyData);

	return res;
}

/++ Простой, но опасный метод, который удаляет туриста по ключу. Требует прав админа! +/
void touristDelete(HTTPContext ctx, size_t num)
{
	import std.conv: text;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`tourist.item`, `delete`), `Недостаточно прав для удаления туриста!`);

	HistoryRecordData historyData = {
		tableName: `tourist`,
		recordNum: num,
		recordKind: HistoryRecordKind.Delete
	};
	sendToHistory(ctx, `Удаление туриста`, historyData);
	getCommonDB().query(`delete from tourist where num = ` ~ num.text);
}
