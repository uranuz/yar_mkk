module mkk_site.main_service.init_history_data;

import mkk_site.main_service.devkit;
import mkk_site.data_model.pohod_edit: PohodDataToWrite, DBName;
import mkk_site.history.client;
import mkk_site.history.common;

shared static this()
{
	MainService.JSON_RPCRouter.join!(pohodInitData)(`pohod.initHistoryData`);
	MainService.JSON_RPCRouter.join!(touristInitData)(`tourist.initHistoryData`);
}

import std.datetime: Date, DateTime;

static immutable pohodFullRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "kod_mkk",
	string, "nomer_knigi",
	string, "region_pohod",
	string, "organization",
	string, "region_group",
	string, "marchrut",
	Date, "begin_date",
	Date, "finish_date",
	size_t, "chef_grupp",
	size_t, "alt_chef",
	size_t, "unit",
	string, "chef_coment",
	string, "MKK_coment",
	size_t[], "unit_neim",
	size_t, "vid",
	size_t, "ks",
	size_t, "elem",
	size_t, "prepar",
	size_t, "stat",
	DateTime, "reg_timestamp",
	DateTime, "last_edit_timestamp",
	size_t, "last_editor_num",
	size_t, "registrator_num",
	string[], "links",
	DateTime, "last_edit_timestamp_utc" // Служебное поле
)();

void pohodInitData(HTTPContext ctx)
{
	if( !ctx.user.isAuthenticated || !ctx.user.isInRole("admin")  )
		throw new Exception(`Недостаточно прав для инициализации истории походов!!!`);

	auto pohod_rs = getCommonDB().query(`
	select
		num,
		kod_mkk,
		nomer_knigi,
		region_pohod,
		organization,
		region_group,
		marchrut,
		begin_date,
		finish_date,
		chef_grupp,
		alt_chef,
		unit,
		chef_coment,
		"MKK_coment",
		unit_neim,
		vid,
		ks,
		elem,
		prepar,
		stat,
		reg_timestamp,
		last_edit_timestamp,
		last_editor_num,
		registrator_num,
		-- Костыль для "правильного" форматирования массива строк
		-- т.к. формат возврата массивов из Postgres не очень стабилен
		case when array_length(links, 1) > 0
			then '["' || array_to_string(links, '","') || '"]' 
			else '[]'
		end links,
		last_edit_timestamp at time zone 'UTC' "last_edit_timestamp_utc"
	from pohod
	`).getRecordSet(pohodFullRecFormat);

	HistoryRecordData[] data;
	data.length = pohod_rs.length;
	size_t i = 0;
	foreach( rec; pohod_rs )
	{
		import std.json: JSONValue;
		JSONValue jData;
		foreach( field; pohodFullRecFormat.names )
			if( field != `last_edit_timestamp_utc` ) // Кроме служебного поля
				jData[field] = rec.getField(field).getStdJSONValue(rec.recordIndex);
		HistoryRecordData item = {
			tableName: "pohod",
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

	sendToHistory(ctx, "Первичное заполнение истории походов", data);
}


static immutable touristFullRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "family_name",
	string, "given_name",
	string, "patronymic",
	string, "birth_date",
	size_t, "birth_year",
	string, "address",
	string, "phone",
	bool, "show_phone",
	string, "email",
	bool, "show_email",
	string, "exp",
	string, "comment",
	size_t, "razr",
	size_t, "sud",
	DateTime, "reg_timestamp",
	DateTime, "last_edit_timestamp",
	size_t, "last_editor_num",
	size_t, "registrator_num",
	DateTime, "last_edit_timestamp_utc" // Служебное поле
)();

void touristInitData(HTTPContext ctx)
{
	if( !ctx.user.isAuthenticated || !ctx.user.isInRole("admin")  )
		throw new Exception(`Недостаточно прав для инициализации истории туристов!!!`);

	auto tourist_rs = getCommonDB().query(`
	select
		num,
		family_name,
		given_name,
		patronymic,
		birth_date,
		birth_year,
		address,
		phone,
		show_phone,
		email,
		show_email,
		exp,
		comment,
		razr,
		sud,
		reg_timestamp,
		last_edit_timestamp,
		last_editor_num,
		registrator_num,
		last_edit_timestamp at time zone 'UTC' "last_edit_timestamp_utc"
	from tourist
	`).getRecordSet(touristFullRecFormat);

	HistoryRecordData[] data;
	data.length = tourist_rs.length;
	size_t i = 0;
	foreach( rec; tourist_rs )
	{
		import std.json: JSONValue;
		JSONValue jData;
		foreach( field; touristFullRecFormat.names )
			if( field != `last_edit_timestamp_utc` ) // Кроме служебного поля
				jData[field] = rec.getField(field).getStdJSONValue(rec.recordIndex);
		HistoryRecordData item = {
			tableName: "tourist",
			recordNum: rec.get!"num"(),
			data: jData,
			userNum: null, // Если не задано - будет явно передано null
			time_stamp: null,
			recordKind: HistoryRecordKind.Update
		};
		if( !rec.isNull("last_editor_num") )
			item.userNum = rec.get!"last_editor_num"();
		if( !rec.isNull("last_edit_timestamp_utc") )
			item.time_stamp = rec.get!"last_edit_timestamp_utc"();
		data[i++] = item;
	}

	sendToHistory(ctx, "Первичное заполнение истории туристов", data);
}
