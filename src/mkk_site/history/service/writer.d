module mkk_site.history.service.writer;

import mkk_site.history.service.service;
import mkk_site.common.utils;
import mkk_site.history.common;

import webtank.db.transaction: makeTransaction;
import webtank.net.utils: PGEscapeStr;
import webtank.net.http.context: HTTPContext;
import webtank.common.optional: Optional;

import std.uuid;
import std.json;

shared static this()
{
	HistoryService.JSON_RPCRouter.join!(writeDataToHistory)(`history.writeData`);
	HistoryService.JSON_RPCRouter.join!(saveActionToHistory)(`history.writeAction`);
}

void writeDataToHistory(HTTPContext ctx, HistoryRecordData[] data)
{
	if( !ctx.user.isAuthenticated )
		throw new Exception(`Недостаточно прав для записи в историю!!!`);

	HistoryRecordData[][string] byTableData;

	HistoryService.loger.info(`Подготовка записи изменений в историю`);

	// Распределяем записи по таблицам
	foreach( item; data )
	{
		if( !item.tableName.length )
			throw new Exception(`"tableName" field expected!!!`);

		if( item.recordNum.isNull )
			throw new Exception(`"recordNum" field expected!!!`);
		
		if( item.userNum.isUndef ) {
			throw new Exception(`"userNum" field expected!!!`);
		}

		if( auto itemsPtr = item.tableName in byTableData ) {
			(*itemsPtr) ~= item;
		} else {
			byTableData[item.tableName] = [item];
		}
	}

	HistoryService.loger.info(`Запуск записи изменений в историю`);

	foreach( tableName, tableData; byTableData ) {
		writeDataForTable(tableData, tableName);
	}
	HistoryService.loger.info(`Завершение записи изменений в историю`);
}

void writeDataForTable(HistoryRecordData[] data, string tableName)
{
	auto db = getHistoryDB();
	auto trans = db.makeTransaction();
	scope(failure) trans.rollback();
	scope(success) trans.commit();

	import std.algorithm: map, filter;
	import std.array: join;
	import std.conv: text, to;

	alias goodItemsFilter = (it) => it.recordNum.isSet;

	auto lastChangesRes = db.query(`
	with rec_nums as(
		select unnest(ARRAY[
		` ~
			data.filter!(goodItemsFilter)
			.map!( (it) => it.recordNum.text )
			.join(`, `)
		~ `
		]::bigint[]) num
	)
	select rec_nums.num, tab.num
	from rec_nums
	inner join "_hc__` ~ tableName ~ `" tab
		on tab.rec_num = rec_nums.num and tab.is_last = true
	for update
	`);
	// Словарь: по номеру записи получаем её последнее изменение в истории
	size_t[size_t] historyNums;
	foreach( recIndex; 0 .. lastChangesRes.recordCount )
	{
		if(
			lastChangesRes.isNull(0, recIndex)
			&& lastChangesRes.isNull(1, recIndex)
		) continue;

		historyNums[
			lastChangesRes.get(0, recIndex).to!size_t
		] = lastChangesRes.get(1, recIndex).to!size_t;
	}

	string preparedData = data.filter!(goodItemsFilter)
		.map!( (item) => [
			item.recordNum.text, // Номер оригинальной записи
			(`'` ~ PGEscapeStr(item.data.toString()) ~ `'::jsonb`), // Измененения
			(item.time_stamp.isSet?
				// Время изменений указано - ставим его
				`'` ~ item.time_stamp.toISOExtString() ~ `'::timestamp without time zone`:
				(item.time_stamp.isUndef?
					// Время изменений не передано устанавливаем текущее
					`current_timestamp at time zone 'UTC'`:
					// Явно указано, что нужно установить null
					`null::timestamp without time zone`)
			), // Время изменений
			(item.userNum.isSet? item.userNum.text: `null::bigint`), // Номер изменившего пользователя
			(cast(ubyte) item.recordKind).text, // Тип записи об изменении
			(item.recordNum.value in historyNums? historyNums[item.recordNum.value].text: `null::bigint`), // Номер пред. изменения
			`true`, // Что это последнее изменение
			(`(select num from _history_action ha where ha.uuid_num = '` ~ PGEscapeStr(item.actionUUID) ~ `'::uuid)`) // Номер действия
		].join(", "))
		.join("),\n(");

	if( preparedData.length )
	{
		// Вставка новых данных в историю
		db.query(`
		insert into "_hc__` ~ tableName ~ `"
		(rec_num, data, time_stamp, user_num, rec_kind, prev_num, is_last, action_num)
		select * from(
			values
			( ` ~ preparedData ~ ` )
		) as dat
		`);
	}

	// Убираем флаг is_last у записей которые 
	db.query(`
	with nums as(
		select unnest(ARRAY[
			` ~ historyNums.byValue().map!( (it) => it.text ).join(", ") ~ `
		]::bigint[]) num
	)
	update "_hc__` ~ tableName ~ `" set is_last = null
	where num in (select num from nums)
	`);
}


size_t saveActionToHistory(HTTPContext ctx, HistoryActionData data)
{
	import std.conv: text, to;
	if( !ctx.user.isAuthenticated )
		throw new Exception(`Недостаточно прав для записи в историю!!!`);

	HistoryService.loger.info(`Начало записи действия в историю`);
	
	auto db = getHistoryDB();

	string insertActionQuery = `
		insert into "_history_action"
		(description, time_stamp, user_num, uuid_num, parent_num)
		values
		( '` ~ PGEscapeStr(data.description) ~ `', '` 
		~ data.time_stamp.toISOExtString() ~ `'::timestamp without time zone, ` 
		~ (data.userNum.isSet? data.userNum.text: `null::bigint`) ~ `, '` 
		~ data.uuid ~ `'::uuid, (select num from _history_action ha where ha.uuid_num = '` 
		~ data.parentUUID ~ `'::uuid limit 1)::bigint )
		returning num
	`;
	Optional!size_t actionNum;
	auto numResult = db.query(insertActionQuery);
	if( numResult.recordCount > 0 && numResult.fieldCount > 0 ) {
		actionNum = numResult.get(0, 0, "0").to!size_t;
	}
	HistoryService.loger.info(`Окончание записи действия в историю`);
	return actionNum;
}