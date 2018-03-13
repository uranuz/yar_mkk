module mkk_site.data_model.full_format;

import std.datetime: Date, DateTime;
import std.array: join;
import std.algorithm: map;
import std.meta: AliasSeq;

import webtank.datctrl.record_format;
import webtank.datctrl.iface.data_field;

alias PohodFullFormatBase = AliasSeq!(
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
	string[], "links"
);

static immutable pohodFullFormat = RecordFormat!(PohodFullFormatBase)();
static immutable pohodFullFormatExt = RecordFormat!(
	PohodFullFormatBase,
	DateTime, "last_edit_timestamp_utc" // Служебное поле
)();

private string getPohodFullQuery(T)(ref T format) {
	return "select\n" ~ format.names.map!( (name) {
		if( name == "last_edit_timestamp_utc" )
			return `last_edit_timestamp at time zone 'UTC'`;
		else if( name == "links" )
// Костыль для "правильного" форматирования массива строк
// т.к. формат возврата массивов из Postgres не очень стабилен
			return `to_json(links) "links"`;
		else
			return `"` ~ name ~ `"`;
	}).join(",\n")
	~ `from pohod `;
}

static immutable string pohodFullQuery;
static immutable string pohodFullQueryExt;

shared static this() {
	pohodFullQuery = getPohodFullQuery(pohodFullFormat);
	pohodFullQueryExt = getPohodFullQuery(pohodFullFormatExt);
}

alias TouristFullFormatBase = AliasSeq!(
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
	size_t, "registrator_num"
);

static immutable touristFullFormat = RecordFormat!(TouristFullFormatBase)();
static immutable touristFullFormatExt = RecordFormat!(
	TouristFullFormatBase,
	DateTime, "last_edit_timestamp_utc" // Служебное поле
)();

private string getTouristFullQuery(T)(ref T format) {
	return "select\n" ~ format.names.map!(
		(name) => (name == "last_edit_timestamp_utc"?
			`last_edit_timestamp at time zone 'UTC'`: `"` ~ name ~ `"`)
	).join(",\n")
	~ `from tourist `;
}

static immutable string touristFullQuery;
static immutable string touristFullQueryExt;
shared static this() {
	touristFullQuery = getTouristFullQuery(touristFullFormat);
	touristFullQueryExt = getTouristFullQuery(touristFullFormatExt);
}