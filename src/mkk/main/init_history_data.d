module mkk.main.init_history_data;

import mkk.main.devkit;
import mkk.main.pohod.model;
import mkk.main.tourist.model;
import mkk.history.client;
import mkk.history.common;

shared static this()
{
	MainService.JSON_RPCRouter.join!(pohodInitData)(`pohod.initHistoryData`);
	MainService.JSON_RPCRouter.join!(touristInitData)(`tourist.initHistoryData`);
}

void pohodInitData(HTTPContext ctx)
{
	initPohodTouristData(ctx,
		pohodFullFormat,
		pohodFullFormatExt,
		pohodFullQueryExt,
		"pohod"
	);
}

void touristInitData(HTTPContext ctx)
{
	initPohodTouristData(ctx,
		touristFullFormat,
		touristFullFormatExt,
		touristFullQueryExt,
		"tourist"
	);
}

void initPohodTouristData(Fmt, FmtExt)(
	HTTPContext ctx,
	ref Fmt format,
	ref FmtExt formatExt,
	string query,
	string tableName)
{
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(tableName ~ `.history`, `init`),
		`Недостаточно прав для инициализации истории!!!`
	);

	auto rs = getCommonDB().query(query).getRecordSet(formatExt);

	HistoryRecordData[] data;
	data.length = rs.length;
	size_t i = 0;
	foreach( rec; rs )
	{
		import std.json: JSONValue;
		JSONValue jData;
		foreach( field; format.names )
			jData[field] = rec.getField(field).getStdJSONValue(rec.recordIndex);
		HistoryRecordData item = {
			tableName: tableName,
			recordNum: rec.get!"num"(0),
			data: jData,
			userNum: null,
			time_stamp: null,
			recordKind: HistoryRecordKind.Update
		};
		if( !rec.isNull("last_editor_num") )
			item.userNum = rec.get!"last_editor_num"();
		if( !rec.isNull("last_edit_timestamp_utc") )
			item.time_stamp = rec.get!"last_edit_timestamp_utc"();
		data[i++] = item;
	}

	sendToHistory(ctx, "Первичное заполнение истории таблицы " ~ tableName, data);
}