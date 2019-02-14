module mkk_site.main_service.pohod.list;

import mkk_site.main_service.devkit;

import mkk_site.data_model.enums;
import mkk_site.data_model.pohod_list;

import webtank.common.optional_date;


shared static this()
{
	MainService.JSON_RPCRouter.join!(recentPohodList)(`pohod.recentList`);
	MainService.JSON_RPCRouter.join!(getPohodList)(`pohod.list`);

	MainService.pageRouter.joinWebFormAPI!(getPohodList)("/api/pohod/list");
}

import std.datetime: Date;
import std.typecons: tuple;
import std.meta: AliasSeq;

alias BasePohodFields = AliasSeq!(
	PrimaryKey!(size_t), "num",
	string, "mkkCode",
	string, "bookNum",
	Date, "beginDate",
	Date, "finishDate",
	typeof(видТуризма), "tourismKind",
	typeof(категорияСложности), "complexity",
	typeof(элементыКС), "complexityElems",
	string, "pohodRegion",
	size_t, "chiefNum",
	string, "chiefFamilyName",
	string, "chiefGivenName",
	string, "chiefPatronymic",
	string, "chiefBirthYear",
	size_t, "partySize",
	string, "organization",
	string, "partyRegion",
	string, "route"
);

static immutable recentPohodRecFormat = RecordFormat!(
	BasePohodFields,
	string, "chiefComment"
)(
	null,
	tuple(
		видТуризма,
		категорияСложности,
		элементыКС
	)
);

static immutable basePohodFieldSubquery =`
	poh.num "num",
	kod_mkk "mkkCode",
	nomer_knigi "bookNum",
	begin_date "beginDate",
	finish_date "finishDate",
	vid "tourismKind",
	ks "complexity",
	elem "complexityElems",
	region_pohod "pohodRegion",
	chief.num "chiefNum",
	chief.family_name "chiefFamilyName",
	chief.given_name "chiefGivenName",
	chief.patronymic "chiefPatronymic",
	chief.birth_year "chiefBirthYear",
	unit "partySize",
	organization,
	region_group "partyRegion",
	marchrut "route",
`;

static immutable recentPohodQuery =
`select ` ~ basePohodFieldSubquery ~ `
	chef_coment "chiefComment"
from pohod poh
left join tourist chief
	on chief.num = poh.chef_grupp
where poh.reg_timestamp is not null
order by poh.reg_timestamp desc nulls last
limit 10
`;

/// Возвращает список последних добавленных походов
auto recentPohodList() {
	return getCommonDB().query(recentPohodQuery).getRecordSet(recentPohodRecFormat);
}


import std.meta: AliasSeq;
import std.typecons: tuple, Tuple;

alias DCTuple = Tuple!(string, `cond`, string, `descr`);

private static immutable pohodDataCheckFilters = [
	DCTuple(
		`finish_date < current_date and prepar < 6`,
		`Сроки истекли, но не указан статус завершения похода`
	),
	DCTuple(
		`nullif(nomer_knigi, '') is null and stat < 4`,
		`Присвоен номер книги, но не указано, что заявка принята`
	),
	DCTuple(
		`begin_date < current_date
			and finish_date > current_date and prepar != 5`,
		`Не установлен статус, что группа на маршруте`
	),
	DCTuple(
		`nullif(region_pohod, '') is null`,
		`Не указан район похода`
	),
	DCTuple(
		`nullif(marchrut, '') is null`,
		`Не указана нитка маршрута`
	),
	DCTuple(
		`vid is null`,
		`Не указан вид туризма`
	),
	DCTuple(
		`begin_date is null`,
		`Не указана дата начала похода`
	),
		DCTuple(
		`finish_date is null`,
		`Не указана дата окончания похода`
	),
		DCTuple(
		`unit is null`,
		`Не указано число участников`
	),
	DCTuple(
		`ks is null`,
		`Не указана категория сложности`
	)
];

import std.algorithm: map;
import std.string: join;
import std.array: array;

// Фильтр для выборки "проблемных" походов при проверке данных
private static immutable string dataCheckFilterQuery =
	pohodDataCheckFilters.map!((dcFilter) => dcFilter.cond).join("\nor\n");

// Подзапрос со списком "проблем" у похода в основную секцию select для списка походов
private static immutable string pohodListDataCheckSubquery =
	"	array(\n" 
	~ pohodDataCheckFilters.map!((dcFilter) =>
		"		select '" ~ dcFilter.descr ~ "'\n			where " ~ dcFilter.cond
	).join("\nunion\n")
	~ "	\n) problems,\n";

// Просто список кортежей, который позволяет установить соответствие между тремя полями
// 0: название поля фильтрации в параметрах метода
// 1: формат перечислимого типа для этого параметра
// 2: соответствующее название поля в структуре ФильтрПоходов
alias PohodEnumFields = AliasSeq!(
	tuple("tourismKind", видТуризма, "vid", "вид туризма"),
	tuple("complexity", категорияСложности, "ks", "категория cложности"),
	tuple("progress", готовностьПохода, "prepar", "готовность похода"),
	tuple("claimState", статусЗаявки, "stat", "статус заявки")
);

//Формирует чать запроса по фильтрации походов (для SQL-секции where)
string getPohodFilterQueryPart(ref PohodFilter filter)
{
	import std.datetime: Date;
	import std.array: join;

	string[] filters;
	foreach( enumSpec; PohodEnumFields ) {
		mixin(`
		if( filter.` ~ enumSpec[0] ~ `.length > 0 )
			filters ~= "\"` ~ enumSpec[2] ~ `\" in(" ~ filter.` ~ enumSpec[0] ~ `.conv!(string[]).join(", ") ~ ")";
		`);
	}

	if( filter.withFiles ) {
		filters ~= `exists( select 1 from pohod_file_link fl where fl.pohod_num = poh.num limit 1 )`;
	}

	static immutable datePartNames = ["year", "month", "day"];
	string[] dateFilters;
	foreach( соотвПоля; соотвПолейСроков )
	{
		OptionalDate dateFilter = filter.dates.get(соотвПоля.имяВФорме, OptionalDate());

		if( dateFilter.isDefined ) {
			dateFilters ~= ` ('` ~ Date( dateFilter.tupleof ).conv!string ~ `'::date `
				~ соотвПоля.опСравн ~ ` ` ~ соотвПоля.имяВБазе ~ `) `;
		}
		else
		{
			foreach( j, частьДаты; dateFilter.tupleof )
			{
				if( !частьДаты.isNull ) {
					dateFilters ~= частьДаты.value.conv!string ~ ` `
						~ соотвПоля.опСравн ~ ` date_part('` ~ datePartNames[j] ~ `', ` ~ соотвПоля.имяВБазе ~ `)`;
				}
			}
		}
	}
	filters ~= dateFilters;

	import std.string: strip;
	filter.pohodRegion = filter.pohodRegion.strip();
	if( filter.pohodRegion.length > 0 )
		filters ~= `region_pohod ILIKE '%` ~ PGEscapeStr(filter.pohodRegion) ~ `%'`;

	if( filter.withDataCheck )
		filters ~= dataCheckFilterQuery;
	

	return ( filters.length > 0? " ( " ~ filters.join(" ) and ( ") ~ " ) ": null );
}

static immutable pohodRecFormat = RecordFormat!(
	BasePohodFields,
	string[], "problems",
	typeof(готовностьПохода), "progress",
	typeof(статусЗаявки), "claimState"
)(
	null,
	tuple(
		видТуризма,
		категорияСложности,
		элементыКС,
		готовностьПохода,
		статусЗаявки
	)
);

private static immutable pohodListFromQueryPart =
`	prepar "progress",
	stat "claimState"
	from pohod poh
	left join tourist chief
		on chief.num = poh.chef_grupp
`;

size_t getPohodCount(PohodFilter filter)
{
	import std.conv: to;
	string query = `select count(1) from pohod poh`;

	if( filter.withFilter )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);

	return getCommonDB().query(query).get(0, 0, "0").to!size_t;
}
//-----------------------------------------------------------------
import mkk_site.data_model.common: Navigation;

IDBQueryResult PohodList(PohodFilter filter, Navigation nav)
{
	import std.conv: text;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	string query = `select ` ~ basePohodFieldSubquery;

	if( filter.withDataCheck )
		query ~= pohodListDataCheckSubquery;
	else
		query ~= "ARRAY[]::text[] problems,\n"; // Пустой список проблем, если нет проверки данных

	query ~= pohodListFromQueryPart;

	if( filter.withFilter )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);

	//nav.normalize(getPohodCount(filter));//****************************************************

	// Упорядочивание и страничный отбор уже делаем по готовым данным
	query ~= ` order by poh.last_edit_timestamp desc nulls last, poh.reg_timestamp desc nulls last, poh.num desc offset `
		~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text;

	return getCommonDB().query(query);
}
//---------------------------------------------------------------
import mkk_site.main_service.pohod.enums: getPohodEnumTypes;

Tuple!(
	IBaseRecordSet, "pohodList",
	Navigation, "pohodNav",
	PohodFilter, "filter",
	typeof(getPohodEnumTypes()), "pohodEnums",
	bool, "isForPrint"
)
getPohodList(PohodFilter filter, Navigation nav)
{
	filter.initializeDates();
	nav.normalize(getPohodCount(filter));

	return typeof(return)(
		PohodList(filter, nav).getRecordSet(pohodRecFormat),
		nav, filter, getPohodEnumTypes(), false);
}
//---------------------------------------------------------------
