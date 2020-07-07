module mkk.main.tourist.list;

import mkk.main.devkit;

import mkk.main.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(touristList)(`tourist.list`);
	MainService.JSON_RPCRouter.join!(plainListTourist)(`tourist.plainList`);

	MainService.pageRouter.joinWebFormAPI!(touristList)("/api/tourist/list");
	MainService.pageRouter.joinWebFormAPI!(plainListTourist)("/api/tourist/plainList");
}

// Структура фильтра по списку туристов
struct TouristListFilter
{
	import webtank.common.optional: Optional;

	@DBField("family_name") string familyName;
	@DBField("given_name") string givenName;
	@DBField("patronymic") string patronymic;
	@DBField("birth_year") Optional!int birthYear;
	@DBField("address") string region;
	@DBField("address") string city;
	@DBField("address") string street;
	@DBField("num") Optional!(size_t[]) nums;
}

import std.typecons: tuple, Tuple;

static immutable shortTouristRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	size_t, "birthYear"
)();

/// Возвращает список туристов с базовой информацией
Tuple!(
	IBaseRecordSet, "touristList",
	Navigation, "nav",
	TouristListFilter, "filter"
)
plainListTourist(TouristListFilter filter, Navigation nav)
{
	auto listRes = getTouristListImpl(
		filter, nav,
		shortTouristRecFormat,
		`num, family_name, given_name, patronymic, birth_year`,
		`family_name, given_name, patronymic`);
	return typeof(return)(listRes.touristList, listRes.nav, filter);
}

static immutable touristListRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	size_t, "birthYear",
	string, "experience",
	string, "phone",
	string, "email",
	typeof(sportCategory), "sportCategory",
	typeof(refereeCategory), "refereeCategory",
	string, "comment"
)(
	tuple(sportCategory, refereeCategory)
);

/// Возвращает список туристов в подробном варианте
Tuple!(
	IBaseRecordSet, "touristList",
	Navigation, "nav",
	TouristListFilter, "filter"
)
touristList(TouristListFilter filter, Navigation nav)
{
	auto listRes = getTouristListImpl(
		filter, nav,
		touristListRecFormat,
		`num,
		family_name,
		given_name,
		patronymic,
		birth_year,
		experience,
		case when show_phone then phone else null end,
		case when show_email then email else null end,
		sport_category "sportCategory",
		referee_category "refereeCategory",
		comment`,
		`family_name, given_name, patronymic`);
	
	return typeof(return)(
		listRes.touristList,
		listRes.nav,
		filter
	);
}

// Реализация двух методов "tourist.list" и "tourist.plainSearch", отличающихся только набором возвращаемых полей
Tuple!(
	IBaseRecordSet, "touristList",
	Navigation, "nav"
)
getTouristListImpl(ResultFormat)(
	TouristListFilter filter,
	Navigation nav,
	ResultFormat resultFormat,
	string queryFields,
	string orderBy
) {
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
			enum string dbFieldName = getUDAs!(__traits(getMember, filter, fieldName), DBField)[0].dbName;
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

	return typeof(return)(
		getCommonDB().query(query).getRecordSet(resultFormat),
		nav
	);
}
