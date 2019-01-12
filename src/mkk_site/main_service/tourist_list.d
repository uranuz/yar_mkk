module mkk_site.main_service.tourist_list;

import std.conv, std.string, std.utf;
import mkk_site.main_service.devkit;
import mkk_site.data_model.enums;

import webtank.common.std_json.to: toStdJSON;

import mkk_site.data_model.tourist_list;

shared static this()
{
	MainService.JSON_RPCRouter.join!(touristList)(`tourist.list`);
	MainService.JSON_RPCRouter.join!(touristPlainSearch)(`tourist.plainSearch`);
}

import std.typecons: tuple;

static immutable shortTouristRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	size_t, "birthYear"
)();

auto touristPlainSearch(TouristListFilter filter, Navigation nav)
{
	return getTouristListImpl(
		filter, nav,
		shortTouristRecFormat,
		`num, family_name, given_name, patronymic, birth_year`,
		`family_name, given_name, patronymic`
	);
}

static immutable touristListRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	size_t, "birthYear",
	string, "experience",
	string, "phone",
	string, "email",
	typeof(спортивныйРазряд), "sportsCategory",
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
		family_name,
		given_name,
		patronymic,
		birth_year,
		exp,
		case when show_phone then phone else null end,
		case when show_email then email else null end,
		razr "sportsCategory",
		sud "refereeCategory",
		comment`,
		`family_name, given_name, patronymic`
	);
}

// Реализация двух методов "tourist.list" и "tourist.plainSearch", отличающихся только набором возвращаемых полей
auto getTouristListImpl(ResultFormat)(
	TouristListFilter filter,
	Navigation nav,
	ResultFormat resultFormat,
	string queryFields,
	string orderBy
) {
	import std.json: JSONValue;
	import std.traits: getUDAs;
	import webtank.common.optional: Optional, isOptional, OptionalValueType;
	import std.conv: text, to;
	import std.meta: AliasSeq, Alias;
	import std.string: join;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

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
				import std.string: strip;
				field = field.strip();
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
				if( field.isSet ) {
					filters ~= dbFieldName ~ ` = any(ARRAY[` ~ field.value.to!(string[]).join(",") ~ `]::integer[])`;
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
	nav.normalize(recordCount);

	query ~=
		(orderBy.length? ` order by ` ~ orderBy: null)
		~ ` offset ` ~ nav.offset.text
		~ ` limit ` ~ nav.pageSize.text;

	return JSONValue([
		"rs": getCommonDB().query(query).getRecordSet(resultFormat).toStdJSON(),
		"nav":  nav.toStdJSON()
	]);
}

shared static this() {
	MainService.pageRouter.joinWebFormAPI!(renderTouristList)("/api/tourist/list");
	MainService.pageRouter.joinWebFormAPI!(renderTouristPlainList)("/api/tourist/plainList");
}

import std.json: JSONValue;
JSONValue renderTouristList(TouristListFilter filter, Navigation nav)
{
	JSONValue callResult = touristList(filter, nav);

	return JSONValue([
		"filter": filter.toStdJSON(),
		"touristList": callResult["rs"],
		"nav": callResult["nav"]
	]);
}

struct ListSettings
{
	string mode; // Режим списка: на добавление/ на удаление записей
	string instanceName; // Название экземпляра компонента
}

JSONValue renderTouristPlainList(TouristListFilter filter, Navigation nav, ListSettings settings)
{
	import std.algorithm: canFind;

	JSONValue callResult = touristPlainSearch(filter, nav);
	JSONValue dataDict = [
		"filter": filter.toStdJSON(),
		"touristList": callResult["rs"],
		"nav": callResult["nav"]
	];

	if( ["add", "remove"].canFind(settings.mode) ) {
		dataDict["mode"] = settings.mode;
	}

	if( settings.instanceName.length > 0 ) {
		dataDict["instanceName"] = settings.instanceName;
	}

	return dataDict;
}