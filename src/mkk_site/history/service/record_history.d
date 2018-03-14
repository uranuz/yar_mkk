module mkk_site.history.service.record_history;

import webtank.common.std_json.to: toStdJSON;
import webtank.net.utils: PGEscapeStr;
import webtank.net.http.context: HTTPContext;
import webtank.common.optional: Optional;

import mkk_site.history.service.service;
import mkk_site.common.utils;
import mkk_site.history.common;
import mkk_site.data_model.common: Navigation;

shared static this()
{
	HistoryService.JSON_RPCRouter.join!(getPohodHistory)(`history.pohod`);
	HistoryService.JSON_RPCRouter.join!(getTouristHistory)(`history.tourist`);
}

import webtank.datctrl.record_format;
import webtank.datctrl.iface.data_field;
import webtank.db.datctrl_joint;

static immutable historyRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "data",
	size_t, "userNum",
	DateTime, "time_stamp"
)();

import std.json: JSONValue, parseJSON, JSON_TYPE;
JSONValue getRecordHistory(HTTPContext ctx, RecordHistoryFilter filter, Navigation nav)
{
	import webtank.datctrl.record_set;
	import std.conv: to, text;
	import std.string: join;
	import std.algorithm: canFind;
	import std.exception;

	enforce( ctx.user.isAuthenticated && (ctx.user.isInRole("admin") || ctx.user.isInRole("moder")),
		`Требуется вход на сайт для просмотра истории изменений!`);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию
	auto history_rs = getHistoryDB().query(`
	select
		num,
		data,
		user_num,
		time_stamp
	from "_hc__` ~ filter.tableName ~ `"
	where rec_num = ` ~ filter.recordNum.text ~ `
	order by time_stamp, num
	offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text ~ `
	`).getRecordSet(historyRecFormat);

	string[] allowedFields = (filter.tableName == `pohod`? [
		"num",
		"kod_mkk",
		"nomer_knigi",
		"region_pohod",
		"organization",
		"region_group",
		"marchrut",
		"begin_date",
		"finish_date",
		"chef_grupp",
		"alt_chef",
		"unit",
		"chef_coment",
		"MKK_coment",
		"unit_neim",
		"vid",
		"ks",
		"elem",
		"prepar",
		"stat",
		"reg_timestamp",
		"last_edit_timestamp",
		"last_editor_num",
		"registrator_num",
		"links"
	]: [
		"num",
		"family_name",
		"given_name",
		"patronymic",
		"birth_date",
		"birth_year",
		"address",
		"phone",
		"show_phone",
		"email",
		"show_email",
		"exp",
		"comment",
		"razr",
		"sud",
		"reg_timestamp",
		"last_edit_timestamp",
		"last_editor_num",
		"registrator_num"
	]);
	

	JSONValue[] items;
	JSONValue prevData;
	foreach( rec; history_rs )
	{
		JSONValue item = [
			"rec": JSONValue(rec.get!"num"()),
			"data": JSONValue(),
			"userNum": (rec.isNull("userNum")? JSONValue(): JSONValue(rec.get!"userNum"())),
			"time_stamp": (rec.isNull("time_stamp")? JSONValue(): JSONValue(rec.get!"time_stamp"().toISOExtString())),
		];
		JSONValue data = rec.getStr!`data`().parseJSON();
		JSONValue changes = (JSONValue[string]).init;
		if( data.type == JSON_TYPE.OBJECT )
		{
			if( prevData.type == JSON_TYPE.OBJECT )
			{
				foreach( string key, JSONValue val; data )
				{
					if( auto prevVal = key in prevData )
					{
						if( *prevVal != val )
							changes[key] = val;
					} else if( val.type != JSON_TYPE.NULL ) {
						changes[key] = null;
					}
				}
				foreach( string key, JSONValue val; prevData )
				{
					if( key !in data && val.type != JSON_TYPE.NULL )
						changes[key] = null;
				}
				foreach( string key, JSONValue val; changes )
				{
					if( !allowedFields.canFind(key) )
						changes.object.remove(key);
				}
			}

			foreach( string key, JSONValue val; data )
			{
				if( !allowedFields.canFind(key) )
					data.object.remove(key);
			}
			item["data"] = data;
			item["changes"] = changes;
		}
		items ~= item;
		prevData = data;
	}
	
	import std.range: retro;
	import std.array: array;
	return JSONValue(items.retro.array);
}

JSONValue getPohodHistory(HTTPContext ctx, RecordHistoryFilter filter, Navigation nav)
{
	filter.tableName = "pohod";
	return getRecordHistory(ctx, filter, nav);
}

JSONValue getTouristHistory(HTTPContext ctx, RecordHistoryFilter filter, Navigation nav)
{
	filter.tableName = "tourist";
	return getRecordHistory(ctx, filter, nav);
}