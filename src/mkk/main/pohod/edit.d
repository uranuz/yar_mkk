module mkk.main.pohod.edit;

import mkk.main.devkit;

import mkk.main.pohod.model;
import mkk.history.client;
import mkk.history.common;

import mkk.main.pohod.read: pohodRead;
import mkk.main.pohod.file_links.edit: writePohodFileLinks;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editPohod)(`pohod.edit`);
	MainService.JSON_RPCRouter.join!(pohodDelete)(`pohod.delete`);

	MainService.pageRouter.joinWebFormAPI!(editPohod)("/api/pohod/edit/results");
}

Tuple!(Optional!size_t, `pohodNum`)
editPohod(HTTPContext ctx, PohodDataToWrite record)
{
	import std.meta: AliasSeq, staticMap;
	import std.algorithm: canFind, countUntil;
	import std.conv: to, text, ConvException;
	import std.typecons: tuple;
	import std.json: JSONValue;
	import mkk.main.enums;
	import std.exception: enforce;
	import std.range: empty;

	enforce(ctx.rights.hasRight(`pohod.item`, `edit`), `Недостаточно прав для редактирования похода!`);
	checkStructEditRights(record, ctx); // Проверка прав на изменение полей

	alias PohodEnums = AliasSeq!(
		tuple("claimState", claimState),
		tuple("tourismKind", tourismKind),
		tuple("complexity", complexity),
		tuple("complexityElems", complexityElems),
		tuple("progress", progress)
	);
	enum string GetFieldName(alias E) = E[0];
	enum enumFieldNames = [staticMap!(GetFieldName, PohodEnums)];

	enforce(
		!record.beginDate.isSet || !record.finishDate.isSet || record.beginDate.value <= record.finishDate.value,
		"Дата начала похода должна быть раньше даты окончания!");

	string[] fieldNames;
	string[] fieldValues;

	MainService.loger.info("Формируем набор строковых полей и значений", "Изменение данных похода");
	mixin(WalkFields!(`record`, q{
		static if( fieldName != "extraFileLinks" )
		{
			fieldNames ~= dbFieldName;

			// Проверка данных на здравый смысл
			static if( enumFieldNames.canFind(fieldName) )
			{
				auto enumFormat = PohodEnums[enumFieldNames.countUntil(fieldName)][1];
				enforce!ConvException(
					!field.isSet || field.value in enumFormat,
					`Выражение "` ~ field.value.text ~ `" не является значением типа "` ~ fieldName ~ `"!`);
			}
			else static if( ["chiefNum", "altChiefNum"].canFind(fieldName) )
			{
				enforce(
					!record.partyNums.isSet || !field.isSet || record.partyNums.value.canFind(field),
					(fieldName == "chiefNum"? "Руководитель": "Заместитель руководителя") ~ " похода должен быть в списке участников!");
			}
			else static if( fieldName == "partyNums" )
			{
				if( !field.isSet ) {
					continue;
				}
				enforce(
					!record.partySize.isSet || !field.isSet || field.length <= record.partySize,
					"Указанное количество участников похода меньше количества добавленных в список!!!");

				if( field.length )
				{
					// Если переданы номера туристов - то проверяем, что они есть в базе
					auto nonExistingNumsResult = getCommonDB().queryParams(
						`select n from (
							select distinct unnest($1::integer[])
						) as nums(n)
						where nums.n not in(select num from tourist)`,
						field);
					enforce(nonExistingNumsResult.fieldCount == 1, "Ошибка при запросе существущих в БД туристах!");

					size_t[] nonExistentNums;
					nonExistentNums.length = nonExistingNumsResult.recordCount;
					foreach( i; 0..nonExistingNumsResult.recordCount ) {
						nonExistentNums[i] = nonExistingNumsResult.get(0, i).to!size_t;
					}
					enforce(
						nonExistentNums.empty,
						"Туристы с номерами: " ~ nonExistentNums.to!string ~ " не найдены в базе данных");
				}
			}

			// Добавление данных на запись в БД
			fieldValues ~= field.toPGString();
		}
	}));

	typeof(return) res;
	if( fieldNames.empty ) {
		return res;
	}

	MainService.loger.info( "Запись автора последних изменений и даты этих изменений", "Изменение данных похода" );
	enforce("userNum" in ctx.user.data, "Не удаётся определить идентификатор пользователя");

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

	MainService.loger.info("Формирование и выполнение запроса к БД", "Изменение данных похода");
	// Собственно запрос на запись данных в БД
	res.pohodNum = getCommonDB().insertOrUpdateTableByNum(`pohod`,
		fieldNames, fieldValues, record.num, safeFieldNames, safeFieldValues);
	if( !res.pohodNum.isSet ) {
		return res;
	}

	auto fullRec = getCommonDB().query(pohodFullQuery ~ ` where num = ` ~ res.pohodNum.text).getRecord(pohodFullFormat);
	JSONValue jFullData;
	foreach( field; pohodFullFormat.names ) {
		jFullData[field] = fullRec.getField(field).getStdJSONValue(fullRec.recordIndex);
	}

	// Сохранение истории действий и изменений
	import webtank.common.std_json.to: toStdJSON;
	record.dbSerializeMode = true; // Пишем в JSON имена полей как в БД
	HistoryRecordData historyData = {
		tableName: `pohod`,
		recordNum: res.pohodNum,
		data: jFullData,
		recordKind: (record.num.isSet? HistoryRecordKind.Update: HistoryRecordKind.Insert)
	};
	sendToHistory(ctx, (record.num.isSet? `Редактирование похода`: `Добавление похода`), historyData);

	writePohodFileLinks(record.extraFileLinks, res.pohodNum.value);

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