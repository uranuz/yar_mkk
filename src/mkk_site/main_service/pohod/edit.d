module mkk_site.main_service.pohod.edit;

import mkk_site.main_service.devkit;
import mkk_site.data_model.pohod_edit: PohodDataToWrite, DBName, PohodFileLink;
import webtank.security.right.common: GetSymbolAccessObject;
import mkk_site.history.client;
import mkk_site.history.common;
import mkk_site.data_model.full_format;

import mkk_site.main_service.pohod.read: pohodRead;
import mkk_site.main_service.pohod.file_links.edit: writePohodFileLinks;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editPohod)(`pohod.edit`);
	MainService.JSON_RPCRouter.join!(pohodDelete)(`pohod.delete`);

	MainService.pageRouter.joinWebFormAPI!(editPohod)("/api/pohod/edit/results");
}

Tuple!(Optional!size_t, `pohodNum`)
editPohod(HTTPContext ctx, PohodDataToWrite record)
{
	import std.meta: AliasSeq, Filter, staticMap;
	import std.traits: isSomeString, getUDAs;
	import std.algorithm: canFind, countUntil;
	import std.conv: to, text, ConvException;
	import std.datetime: Date;
	import std.typecons: tuple;
	import std.string: strip, join;
	import std.json: JSONValue;
	import mkk_site.data_model.enums;
	import webtank.net.utils: PGEscapeStr;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`pohod.item`, `edit`), `Недостаточно прав для редактирования похода!`);

	string[] fieldNames;
	string[] fieldValues;

	alias PohodEnums = AliasSeq!(
		tuple("claimState", статусЗаявки),
		tuple("tourismKind", видТуризма),
		tuple("complexity", категорияСложности),
		tuple("complexityElems", элементыКС),
		tuple("progress", готовностьПохода)
	);
	enum string GetFieldName(alias E) = E[0];
	enum enumFieldNames = [staticMap!(GetFieldName, PohodEnums)];

	if( record.beginDate.isSet
		&& record.finishDate.isSet
		&& record.finishDate.value < record.beginDate.value
	) {
		throw new Exception("Дата начала похода должна быть раньше даты окончания!!!");
	}

	MainService.loger.info("Формируем набор строковых полей и значений", "Изменение данных похода");
	foreach( fieldName; AliasSeq!(__traits(allMembers, PohodDataToWrite)) )
	{
		alias FieldType = typeof(__traits(getMember, record, fieldName));
		static if( isOptional!FieldType && OptionalIsUndefable!FieldType ) {
			auto field = __traits(getMember, record, fieldName);
			if( field.isUndef  )
				continue; // Поля, которые undef с нашей т.зрения не изменились

			string accessObj = GetSymbolAccessObject!(PohodDataToWrite, fieldName)();
			enforce(ctx.rights.hasRight(accessObj, `edit`), `Недостаточно прав для редактирования поля похода: ` ~ fieldName);
			if( fieldName == "extraFileLinks" )
				continue; // Ссылки обрабатываем позже

			enum string dbFieldName = getUDAs!(__traits(getMember, record, fieldName), DBName)[0].dbName;
			fieldNames ~= `"` ~ dbFieldName ~ `"`;
			static if( isSomeString!( OptionalValueType!FieldType ) )
			{
				// Для строковых полей обрамляем в кавычки и экранируем для вставки в запрос к БД
				fieldValues ~= ( (field.isSet && field.length > 0)? "'" ~ PGEscapeStr(field.value) ~ "'": "NULL" );
			}
			else static if( enumFieldNames.canFind(fieldName) )
			{
				auto enumFormat = PohodEnums[enumFieldNames.countUntil(fieldName)][1];
				if( field.isSet && field.value !in enumFormat ) {
					throw new ConvException(`Выражение "` ~ field.value.text ~ `" не является значением типа "` ~ fieldName ~ `"!!!`);
				}
				fieldValues ~= field.isSet? field.text: "NULL";
			}
			else static if( is(OptionalValueType!FieldType == Date) )
			{
				fieldValues ~= field.isSet? "'" ~ field.toISOExtString() ~ "'": "NULL";
			}
			else static if( fieldName == "extraFileLinks" )
			{
				// Ссылки обрабатываются потом
			}
			else static if( ["chiefNum", "altChiefNum"].canFind(fieldName) )
			{
				if( record.partyNums.isSet && field.isSet && !record.partyNums.value.canFind(field) ) {
					throw new Exception(
						(fieldName == "chiefNum"? "Руководитель": "Заместитель руководителя")
						~ " похода должен быть в списке участников!!!"
					);
				}
				fieldValues ~= field.isSet? field.text: "NULL";
			}
			else static if( fieldName == "partyNums" )
			{
				if( field.isNull )
				{
					fieldValues ~= "NULL";
					continue;
				}
				if( record.partySize.isSet && field.isSet && record.partySize < field.length ) {
					throw new Exception("Указанное количество участников похода меньше количества добавленных в список!!!");
				}

				string keysQueryPart = field.value.to!(string[]).join(", ");
				if( field.length )
				{
					// Если переданы номера туристов - то проверяем, что они есть в базе
					auto nonExistingNumsResult = getCommonDB().query (
						`with nums as(
							select distinct unnest(ARRAY[` ~ keysQueryPart ~ `]::integer[]) as n
						) select n from nums
						where n not in(select num from tourist)`
					);
					if( nonExistingNumsResult.fieldCount != 1 )
						throw new Exception("Ошибка при запросе существущих в БД туристах!!!");

					size_t[] nonExistentNums;
					nonExistentNums.length = nonExistingNumsResult.recordCount;
					foreach( i; 0..nonExistingNumsResult.recordCount ) {
						nonExistentNums[i] = nonExistingNumsResult.get(0, i).to!size_t;
					}
					if( nonExistentNums.length > 0 ) {
						throw new Exception("Туристы с номерами: " ~ nonExistentNums.to!string ~ " не найдены в базе данных");
					}
				}

				fieldValues ~= "ARRAY[" ~ keysQueryPart ~ "]";
			} else static if( fieldName == "partySize" ) {
				fieldValues ~= field.isSet? field.text: "NULL";
			} else {
				static assert(false, `Unprocessed Undefable field: ` ~ fieldName); // Не написан код для обработки поля Undefable
			}
		}
	}

	typeof(return) res;
	if( fieldNames.length > 0 )
	{
		MainService.loger.info( "Запись автора последних изменений и даты этих изменений", "Изменение данных похода" );
		if( "userNum" !in ctx.user.data ) {
			throw new Exception("Не удаётся определить идентификатор пользователя");
		}
		fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
		fieldValues ~= [ctx.user.data["userNum"], "current_timestamp"];
		MainService.loger.info("Формирование и выполнение запроса к БД", "Изменение данных похода");
		string queryStr;

		import std.array: join;
		if( record.num.isSet ) {
			queryStr = "update pohod set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num = '" ~ record.num.text ~ "' returning num";
		}
		else
		{
			MainService.loger.info("Запись пользователя, добавившего поход и даты добавления", "Изменение данных похода");

			fieldNames ~= ["registrator_num", "reg_timestamp"];
			fieldValues ~= [ctx.user.data["userNum"], "current_timestamp"];
			queryStr = "insert into pohod ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " ) returning num";
		}

		auto writeQueryRes = getCommonDB().query(queryStr); // Собственно запрос на запись данных в БД
		if( writeQueryRes && writeQueryRes.recordCount == 1 )
		{
			size_t recordNum = writeQueryRes.get(0, 0, null).to!size_t;
			
			auto full_rec = getCommonDB().query(
				pohodFullQuery ~ ` where num = ` ~ recordNum.text).getRecordSet(pohodFullFormat).front;
			JSONValue jFullData;
			foreach( field; pohodFullFormat.names )
				jFullData[field] = full_rec.getField(field).getStdJSONValue(full_rec.recordIndex);
			
			// Сохранение истории действий и изменений
			import webtank.common.std_json.to: toStdJSON;
			
			record.dbSerializeMode = true; // Пишем в JSON имена полей как в БД
			HistoryRecordData historyData = {
				tableName: `pohod`,
				recordNum: recordNum,
				data: jFullData,
				recordKind: (record.num.isSet? HistoryRecordKind.Update: HistoryRecordKind.Insert)
			};
			sendToHistory(ctx, (record.num.isSet? `Редактирование похода`: `Добавление похода`), historyData);

			writePohodFileLinks(record.extraFileLinks, recordNum);
			res.pohodNum = recordNum;
		}
	}

	MainService.loger.info("Выполнение запроса к БД завершено", "Изменение данных похода");
	return res;
}


/++ Простой, но опасный метод, который удаляет поход по ключу. Требует прав админа! +/
void pohodDelete(HTTPContext ctx, size_t num)
{
	import std.conv: text;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`pohod.item`, `delete`), `Недостаточно прав для удаления похода!`);

	HistoryRecordData historyData = {
		tableName: `pohod`,
		recordNum: num,
		recordKind: HistoryRecordKind.Delete
	};
	sendToHistory(ctx, `Удаление похода`, historyData);
	getCommonDB().query(`delete from pohod where num = ` ~ num.text);
}