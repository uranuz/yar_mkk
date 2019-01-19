module mkk_site.main_service.tourist.edit;

import mkk_site.main_service.devkit;
import mkk_site.data_model.tourist_edit;
import mkk_site.history.client;
import mkk_site.history.common;
import mkk_site.data_model.full_format;
import webtank.security.right.common: GetSymbolAccessObject;

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
	import std.meta: AliasSeq, Filter, staticMap;
	import std.traits: isSomeString, getUDAs;
	import std.algorithm: canFind, countUntil;
	import std.conv: to, text, ConvException;
	import std.typecons: tuple;
	import mkk_site.data_model.enums;
	import webtank.net.utils: PGEscapeStr;
	import std.array: join;
	import std.json: JSONValue;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`tourist.item`, `edit`), `Недостаточно прав для редактирования туриста!`);

	string[] fieldNames; // имена полей для записи
	string[] fieldValues; // значения полей для записи

	alias TouristEnums = AliasSeq!(
		tuple("sportsCategory", спортивныйРазряд),
		tuple("refereeCategory", судейскаяКатегория)
	);
	enum string GetFieldName(alias E) = E[0];
	enum enumFieldNames = [staticMap!(GetFieldName, TouristEnums)];

	foreach( fieldName; AliasSeq!(__traits(allMembers, TouristDataToWrite)) )
	{
		alias FieldType = typeof(__traits(getMember, record, fieldName));
		static if( isOptional!FieldType && OptionalIsUndefable!FieldType )
		{
			auto field = __traits(getMember, record, fieldName);

			if( field.isUndef )
				continue; // Поля, которые undef с нашей т.зрения не изменились
			string accessObj = GetSymbolAccessObject!(TouristDataToWrite, fieldName)();
			enforce(ctx.rights.hasRight(accessObj, `edit`), `Недостаточно прав для редактирования поля: ` ~ fieldName);

			enum DBFields = getUDAs!(__traits(getMember, record, fieldName), DBName);
			static if( DBFields.length > 0 ) {
				fieldNames ~= `"` ~ DBFields[0].dbName ~ `"`;
			}

			static if( isSomeString!( OptionalValueType!FieldType ) )
			{
				// Для строковых полей обрамляем в кавычки и экранируем для вставки в запрос к БД
				fieldValues ~= (field.isSet && field.length > 0)? "'" ~ PGEscapeStr(field.value) ~ "'": "NULL";
			}
			else static if( enumFieldNames.canFind(fieldName) )
			{
				auto enumFormat = TouristEnums[enumFieldNames.countUntil(fieldName)][1];
				if( field.isSet && field.value !in enumFormat ) {
					throw new ConvException(`Выражение "` ~ field.value.text ~ `" не является значением типа "` ~ fieldName ~ `"!!!`);
				}
				fieldValues ~= field.isSet? field.text: "NULL";
			}
			else static if( is(OptionalValueType!FieldType == bool) )
			{
				fieldValues ~= field.isSet? (field.value? "true": "false"): "NULL";
			}
			else static if( fieldName == "birthYear" )
			{
				fieldValues ~= field.isSet? field.value.text: "NULL";
			}
			else static if( fieldName == "birthMonth" )
			{
				if( field.isSet && (field < 1 || field > 12) ) {
					throw new Exception("Номер месяца должен быть числом от 1 до 12!!!");
				}
				if( field.isSet && (field < 1 || field > 31) ) {
					throw new Exception("День месяца должен быть числом от 1 до 31!!!");
				}

				if( record.birthDay.isNull && record.birthMonth.isNull ) {
					fieldValues ~= "NULL";
				} else {
					fieldValues ~= (record.birthDay.isSet? record.birthDay.text: null)
						~ `.` ~ (record.birthMonth.isSet? record.birthMonth.text: null);
				}
			} else static if( fieldName == "birthDay" ) {
				// Ничего не делаем - специально оставлено пусто
			} else {
				static assert(false, `Unprocessed Undefable field: ` ~ fieldName);
			}
		}
	}

	auto res = typeof(return)(record.num);
	if( fieldNames.length > 0 )
	{
		if( "userNum" !in ctx.user.data ) {
			throw new Exception("Не удаётся определить идентификатор пользователя");
		}
		//Запись автора последних изменений и даты этих изменений
		fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
		fieldValues ~= [ctx.user.data["userNum"], "current_timestamp"];

		string queryStr;
		if( record.num.isSet )
		{
			queryStr = "update tourist set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num = '" ~ record.num.text ~ "' returning num";
		}
		else
		{
			fieldNames ~= ["registrator_num", "reg_timestamp"] ;
			fieldValues ~= [ctx.user.data["userNum"], "current_timestamp"];
			queryStr = "insert into tourist ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " ) returning num";
		}

		auto writeQueryRes = getCommonDB().query(queryStr);
		if( writeQueryRes && writeQueryRes.recordCount == 1 )
		{
			size_t recordNum = writeQueryRes.get(0, 0, null).to!size_t;
			
			auto full_rec = getCommonDB().query(
				touristFullQuery ~ ` where num = ` ~ recordNum.text).getRecordSet(touristFullFormat).front;
			JSONValue jFullData;
			foreach( field; touristFullFormat.names )
				jFullData[field] = full_rec.getField(field).getStdJSONValue(full_rec.recordIndex);
			
			// Сохранение истории действий и изменений
			import webtank.common.std_json.to: toStdJSON;
			record.dbSerializeMode = true; // Пишем в JSON имена полей как в БД
			HistoryRecordData historyData = {
				tableName: `tourist`,
				recordNum: writeQueryRes.get(0, 0, null).to!size_t,
				data: jFullData,
				recordKind: (record.num.isSet? HistoryRecordKind.Update: HistoryRecordKind.Insert)
			};
			sendToHistory(ctx, (record.num.isSet? `Редактирование туриста`: `Добавление туриста`), historyData);
			res.touristNum = writeQueryRes.get(0, 0, null).to!size_t;
		}
	}

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
