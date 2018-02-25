module mkk_site.history.service.writer;

import mkk_site.history.service.service;
import mkk_site.common.utils;
import mkk_site.history.common;

import webtank.db.transaction: PostgreSQLTransaction;
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

void writeDataToHistory(HTTPContext ctx, HistoryRecordData data)
{
	//if( !ctx.user.isAuthenticated )
	//	throw new Exception(`Недостаточно прав для записи в историю!!!`);
	
	import std.conv: text, to;

	if( !data.tableName.length )
		throw new Exception(`"tableName" field expected!!!`);

	if( data.recordNum.isNull )
		throw new Exception(`"recordNum" field expected!!!`);

	if( data.userNum.isNull ) {
		throw new Exception(`"userNum" field expected!!!`);
	}
		
	
	auto db = getHistoryDB();
	auto trans = new PostgreSQLTransaction(db);
	scope(failure) trans.rollback();
	scope(success) trans.commit();

	string getLastQuery = `
	with updating as(
		select num, tab.is_last
		from "_hc__` ~ data.tableName ~ `" tab
		where tab.rec_num = ` ~ data.recordNum.text ~ `
		for update
	)
	select num from updating where is_last = true
	order by num
	`;

	auto getLastQueryRes = db.query(getLastQuery);
	Optional!size_t oldLastNum;
	if( getLastQueryRes.recordCount > 0 && getLastQueryRes.fieldCount > 0 ) {
		oldLastNum = getLastQueryRes.get(0, 0, "0").to!size_t;
	}

	string dropLastQuery = `
	update "_hc__` ~ data.tableName ~ `" set is_last = null where rec_num = ` ~ data.recordNum.text ~ `
	`;
	db.query(dropLastQuery);

	string insertNewQuery = `
	insert into "_hc__` ~ data.tableName ~ `"
	(rec_num, data, time_stamp, user_num, rec_kind, prev_num, is_last, action_num)
	values
	( ` ~ data.recordNum.text ~ `, '` ~ PGEscapeStr(data.data.toString()) ~ `'::jsonb, current_timestamp, ` ~ data.userNum.text ~ `, 1, ` ~ (oldLastNum.isNull? `null`: oldLastNum.text) ~ `, true, (select num from _history_action ha where ha.uuid_num = '` ~ PGEscapeStr(data.actionUUID) ~ `'::uuid) )
	`;

	db.query(insertNewQuery);
}




size_t saveActionToHistory(HistoryActionData data)
{
	import std.conv: text, to;
	
	auto db = getHistoryDB();

	string insertActionQuery = `
		insert into "_history_action"
		(description, time_stamp, user_num, uuid_num, parent_num)
		values
		( '` ~ PGEscapeStr(data.description) ~ `', '` ~ data.time_stamp.toISOExtString() ~ `'::timestamp without time zone, ` ~ data.userNum.text ~ `, '` ~ data.uuid ~ `'::uuid, (select num from _history_action ha where ha.uuid_num = '` ~ data.parentUUID ~ `'::uuid limit 1)::bigint )
		returning num
	`;
	Optional!size_t actionNum;
	auto numResult = db.query(insertActionQuery);
	if( numResult.recordCount > 0 && numResult.fieldCount > 0 ) {
		actionNum = numResult.get(0, 0, "0").to!size_t;
	}
	return actionNum;
}