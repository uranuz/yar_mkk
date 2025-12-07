module mkk.main.pohod.edit;

import mkk.main.devkit;

import mkk.main.pohod.model;
import webtank.history.client;
import webtank.history.common;

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
	import std.algorithm: canFind, countUntil, map;
	import std.array: array;
	import std.conv: text, ConvException;
	import std.json: JSONValue;
	import mkk.main.enums;
	import webtank.security.right.access_exception: AccessException;

	enforce!AccessException(
		ctx.rights.hasRight(`pohod.item`, `edit`),
		`Недостаточно прав для редактирования похода!`);
	checkStructEditRights(record, ctx); // Проверка прав на изменение полей

	static immutable pohodEnums = [
		tuple("claimState", claimState),
		tuple("tourismKind", tourismKind),
		tuple("complexity", complexity),
		tuple("complexityElem", complexityElem),
		tuple("progress", progress)
	];
	static immutable string[] pohodEnumNames = pohodEnums.map!((it) => it[0]).array;

	enforce(
		!record.beginDate.isSet || !record.finishDate.isSet || record.beginDate.value <= record.finishDate.value,
		"Дата начала похода должна быть раньше даты окончания!");

	string[] fieldNames;
	string[] fieldValues;

	ctx.service.log.info("Формируем набор строковых полей и значений", "Изменение данных похода");
	mixin(WalkFields!(`record`, q{
		// Поля, которые не хранятся в самой записи похода, а поэтому записываются отдельно
		enum bool externField = ["extraFileLinks", "partyNums"].canFind(fieldName);

		// Проверка данных на здравый смысл
		static if( pohodEnumNames.canFind(fieldName) )
		{
			auto enumFormat = pohodEnums[pohodEnumNames.countUntil(fieldName)][1];
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
		
		static if( !externField )
		{
			fieldNames ~= dbFieldName;
			// Добавление данных на запись в БД
			fieldValues ~= field.toPGString();
		}
	}));

	typeof(return) res;
	if( fieldNames.empty ) {
		return res;
	}

	ctx.service.log.info( "Запись автора последних изменений и даты этих изменений", "Изменение данных похода" );
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

	ctx.service.log.info("Формирование и выполнение запроса к БД", "Изменение данных похода");
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

	writePohodParty(record, res.pohodNum.value);

	writePohodFileLinks(record.extraFileLinks, res.pohodNum.value);

	ctx.service.log.info("Выполнение запроса к БД завершено", "Изменение данных похода");
	return res;
}

void writePohodParty(ref PohodDataToWrite record, size_t pohodNum)
{
	import std.conv: text;

	if( record.partyNums.isUndef )
		return;

	enforce(
		!record.partySize.isSet || !record.partyNums.isSet || record.partyNums.length <= record.partySize,
		"Указанное количество участников похода меньше количества добавленных в список!!!");

	if( record.partyNums.isSet && record.partyNums.length )
	{
		// Если переданы номера туристов - то проверяем, что они есть в базе
		auto nonExisting = getCommonDB().queryParams(
			`select array_agg(tr.num)
			from (
				select unnest($1::integer[])
			) as nums(num)
			left join tourist tr
				on tr.num = nums.num
			where tr.num is null`,
			record.partyNums
		).getScalar!(size_t[]);

		enforce(nonExisting.empty, "Туристы с номерами: " ~ nonExisting.text ~ " не найдены в базе данных");
	}

	getCommonDB().queryParams(
`with inp(num) as(
	select unnest($1::integer[])
),
-- Участники для добавления в базу
new_parts as(
	select $2::integer, inp.num
	from inp
	left join pohod_party php
		on
			php.tourist_num = inp.num
			and
			php.pohod_num = $2::integer
	where
		php.num is null -- Новые записи, которых нет в базе, но есть во вводе
),
-- Участники для удаления из базы
del_parts as(
	select php.num
	from pohod_party php
	left join inp
		on
			inp.num = php.tourist_num
	where
		php.pohod_num = $2::integer
		and
		inp.num is null -- Записи для удаления, которых нет во вводе, но есть в базе
),
deleted as(
	-- Удаляем...
	delete from pohod_party as del_php
	where del_php.num in(select dp.num from del_parts dp)
	returning del_php.num, false "new"
),
inserted as(
	-- Добавляем
	insert into pohod_party as ins_php(pohod_num, tourist_num)
	select * from new_parts
	returning ins_php.num, true "new"
)
select * from deleted
union all
select * from inserted
`, record.partyNums, pohodNum);
}


/++ Простой, но опасный метод, который удаляет поход по ключу. Требует прав админа! +/
void pohodDelete(HTTPContext ctx, size_t num)
{
	import webtank.security.right.access_exception: AccessException;

	enforce!AccessException(
		ctx.rights.hasRight(`pohod.item`, `delete`),
		`Недостаточно прав для удаления похода!`);

	HistoryRecordData historyData = {
		tableName: `pohod`,
		recordNum: num,
		recordKind: HistoryRecordKind.Delete
	};
	sendToHistory(ctx, `Удаление похода`, historyData);
	getCommonDB().queryParams(`delete from pohod where num = $1`, num);
	getCommonDB().queryParams(`delete from pohod_party where pohod_num = $1`, num);
}