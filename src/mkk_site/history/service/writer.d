module mkk_site.history.service.writer;

import mkk_site.history.service.service;
import mkk_site.common.utils;

import webtank.db.transaction: PostgreSQLTransaction;

import std.uuid;
import std.json;



void saveDataToHistory(
	string tableName, size_t recNum, JSONValue oldData, JSONValue newData, size_t userNum, bool isSnapshot=false)
{
	import std.conv: text, to;
	
	auto db = getHistoryDB();
	auto trans = new PostgreSQLTransaction(db);
	scope(failure) trans.rollback();
	scope(success) trans.commit();



	string getLastQuery = `
		select num
		from "_hc__` ~ tableName ~ `" tab
		where tab.rec_num = ` ~ recNum.text ~ ` and tab.is_last = true
		for update
	`;

	auto getLastQueryRes = db.query(getLastQuery);
	size_t oldLastNum = getLastQueryRes.get(0, 0, "0").to!size_t;

	/*
	string insertNewQuery = `
		insert into "_hc__` ~ tableName ~ `" tab
		(rec_num, old_data, new_data, time_stamp, user_num, rec_kind, prev_num, is_last, action_num)
		values
		( ` ~ recNum.text ~ `, ` ~  ~ ` )
	`;
	*/



}




UUID saveActionToHistory()
{


	string insertActionQuery = `
		insert into "_history_action"
		(num, description, time_stamp, parent_num, user_num)
		values
		()
	`;
	return UUID();
}