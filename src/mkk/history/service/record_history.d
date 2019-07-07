module mkk.history.service.record_history;

import webtank.common.std_json.to: toStdJSON;
import webtank.net.http.context: HTTPContext;
import webtank.common.optional: Optional;
import webtank.net.http.handler.web_form_api_page_route: joinWebFormAPI;
import webtank.datctrl.navigation: Navigation;

import mkk.history.service.service;
import mkk.common.utils;
import mkk.history.common;

shared static this()
{
	HistoryService.JSON_RPCRouter.join!(getRecordHistory)(`history.list`);

	HistoryService.pageRouter.joinWebFormAPI!(getRecordHistory)("/history/api/{objectName}/history");
}

import webtank.datctrl.record_format;
import webtank.datctrl.iface.data_field;
import webtank.db.datctrl_joint;

import std.datetime: DateTime;
static immutable historyRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "data",
	size_t, "userNum",
	DateTime, "time_stamp"
)();

import std.json: JSONValue, parseJSON, JSONType;
JSONValue getRecordHistory(HTTPContext ctx, RecordHistoryFilter filter, Navigation nav)
{
	import webtank.datctrl.record_set;
	import std.conv: to, text;
	import std.string: join;
	import std.algorithm: canFind;
	import std.exception: enforce;

	enforce([`pohod`, `tourist`].canFind(filter.objectName), `Просмотр истории пока доступен только для походов или туристов`);
	enforce(ctx.rights.hasRight(filter.objectName ~ `.history`, `read`),
		`Недостаточно прав для просмотра истории изменений!`
	);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию
	auto history_rs = getHistoryDB().query(`
	select
		num,
		data,
		user_num,
		time_stamp
	from "_hc__` ~ filter.objectName ~ `"
	where rec_num = ` ~ filter.num.text ~ `
	order by time_stamp, num
	offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text ~ `
	`).getRecordSet(historyRecFormat);

	string[] allowedFields = (filter.objectName == `pohod`? [
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
		if( data.type == JSONType.object )
		{
			if( prevData.type == JSONType.object )
			{
				foreach( string num, JSONValue val; data )
				{
					if( auto prevVal = num in prevData )
					{
						if( *prevVal != val )
							changes[num] = val;
					} else if( val.type != JSONType.null_ ) {
						changes[num] = null;
					}
				}
				foreach( string num, JSONValue val; prevData )
				{
					if( num !in data && val.type != JSONType.null_ )
						changes[num] = null;
				}
				foreach( string num, JSONValue val; changes )
				{
					if( !allowedFields.canFind(num) )
						changes.object.remove(num);
				}
			}

			foreach( string num, JSONValue val; data )
			{
				if( !allowedFields.canFind(num) )
					data.object.remove(num);
			}
			item["data"] = data;
			item["changes"] = changes;
		}
		items ~= item;
		prevData = data;
	}
	
	import std.range: retro;
	import std.array: array;
	return JSONValue([
		`history`: JSONValue(items.retro.array),
		`objectName`: JSONValue(filter.objectName)
	]);
}