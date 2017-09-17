module mkk_site.main_service.tourist_list;

import std.conv, std.string, std.utf;
import mkk_site.main_service.devkit;
import mkk_site.site_data;

import mkk_site.data_defs.tourist_list;

shared static this()
{
	Service.JSON_RPCRouter.join!(touristList)(`tourist.list`);
	Service.JSON_RPCRouter.join!(touristPlainSearch)(`tourist.plainSearch`);
}

import std.typecons: tuple;

static immutable shortTouristRecFormat = RecordFormat!(
	PrimaryKey!(int), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	int, "birthYear"
)();

auto touristPlainSearch(TouristListFilter filter, Navigation nav)
{
	return getTouristListImpl(
		filter, nav,
		shortTouristRecFormat,
		`num, family_name, given_name, patronymic, birth_year`
	);
}

static immutable touristListRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "nameAndYear",
	string,  "experience",
	string, "contacts",
	typeof(спортивныйРазряд),  "sportsCategory",
	typeof(судейскаяКатегория), "refereeCategory",
	string, "comment"
)(
	null,
	tuple(спортивныйРазряд, судейскаяКатегория)
);

auto touristList(TouristListFilter filter, Navigation nav)
{
	return getTouristListImpl(
		filter, nav,
		touristListRecFormat,
		`num,
		(
			coalesce(family_name, '') ||
			coalesce(' ' || given_name, '') ||
			coalesce(' ' || patronymic, '') ||
			coalesce(', ' || birth_year::text, '')
		) "nameAndYear",
		coalesce(exp, '???') "experience",
		(
			case
				when( show_phone = true ) then phone||'<br> '
			else '' end ||
			case
				when( show_email = true ) then email
			else '' end
		) "contacts",
		razr "sportsCategory",
		sud "refereeCategory",
		comment`
	);
}

// Реализация двух методов "tourist.list" и "tourist.plainSearch", отличающихся только набором возвращаемых полей
auto getTouristListImpl(ResultFormat)(
	TouristListFilter filter,
	Navigation nav,
	ResultFormat resultFormat,
	string queryFields
) {
	import std.json: JSONValue;
	import std.traits: getUDAs;
	import webtank.common.optional: Optional, isOptional, OptionalValueType;
	import std.conv: text, to;
	import std.meta: AliasSeq, Alias;
	import std.string: join;

	static immutable size_t maxPageSize = 50;
	string[] filters;
	if( nav.pageSize > maxPageSize ) {
		nav.pageSize = maxPageSize;
	}

	foreach( fieldName; AliasSeq!(__traits(allMembers, TouristListFilter)) )
	{
		alias FieldType = typeof(__traits(getMember, filter, fieldName));
		static if( __traits(compiles, {
			FieldType test = FieldType.init;
		})) {
			enum string dbFieldName = getUDAs!(__traits(getMember, filter, fieldName), DBName)[0].dbName;
			auto field = __traits(getMember, filter, fieldName);
			static if( is( FieldType == string ) )
			{
				if( field.length > 0 ) {
					filters ~= dbFieldName ~ ` ilike '%` ~ PGEscapeStr(field) ~ `%'`;
				}
			}
			else static if( isOptional!FieldType && is( OptionalValueType!(FieldType) == int ) )
			{
				if( field.isSet ) {
					filters ~= dbFieldName ~ ` = ` ~ field.text;
				}
			}
			else static if( fieldName == "nums" )
			{
				if( field.length > 0 ) {
					filters ~= dbFieldName ~ ` in(` ~ field.to!(string[]).join(",") ~ `)`;
				}
			}
		}
	}

	string query = `select ` ~ queryFields ~ ` from tourist `;
	string countQuery = `select count(1) from tourist `;
	if( filters.length > 0 )
	{
		string filtersPart = "where (" ~ filters.join(") and (") ~ ")";
		query ~= filtersPart;
		countQuery ~= filtersPart;
	}
	size_t recordCount = getCommonDB().query(countQuery).get(0, 0, "0").to!size_t;
	if( recordCount < nav.offset ) {
		// Устанавливаем offset на начало последней страницы, если offset выходит за число записей
		nav.offset = (recordCount / nav.pageSize) * nav.pageSize;
	}

	query ~= ` offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text;

	JSONValue result;
	result[`nav`] = JSONValue([
		`offset`: JSONValue(nav.offset),
		`pageSize`: JSONValue(nav.pageSize),
		`recordCount`: JSONValue(recordCount)
	]);
	result[`rs`] = getCommonDB().query(query).getRecordSet(resultFormat).toStdJSON();

	return result;
}