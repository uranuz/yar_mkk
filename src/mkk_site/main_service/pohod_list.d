module mkk_site.main_service.pohod_list;

import mkk_site.main_service.devkit;
import mkk_site.data_model.enums;
import mkk_site.data_model.pohod_list;

import webtank.common.std_json.to: toStdJSON;

shared static this()
{
	MainService.JSON_RPCRouter.join!(recentPohodList)(`pohod.recentList`);
	MainService.JSON_RPCRouter.join!(getPohodEnumTypes)(`pohod.enumTypes`);
	MainService.JSON_RPCRouter.join!(getPohodList)(`pohod.list`);
	MainService.JSON_RPCRouter.join!(getPartyList)(`pohod.partyList`);
	MainService.JSON_RPCRouter.join!(partyInfo)(`pohod.partyInfo`);
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

static immutable basePohodFieldSuquery =`
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
`select ` ~ basePohodFieldSuquery ~ `
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

import std.json: JSONValue;
static immutable JSONValue pohodEnumTypes;
shared static this() {
	pohodEnumTypes = JSONValue([
		`tourismKind`: видТуризма.toStdJSON(),
		`complexity`: категорияСложности.toStdJSON(),
		`progress`: готовностьПохода.toStdJSON(),
		`claimState`: статусЗаявки.toStdJSON()
	]);
}

/++ Возвращает JSON с перечислимыми типами, относящимися к походу +/
JSONValue getPohodEnumTypes() {
	return pohodEnumTypes;
}

static immutable participantInfoRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	int, "birthYear"
)();

IBaseRecordSet getPartyList(Optional!size_t num)
{
	import webtank.datctrl.record_set;
	import std.conv: text;
	if( num.isNull ) {
		return makeMemoryRecordSet(participantInfoRecFormat);
	}

	return getCommonDB().query(
`with tourist_num as(
	select unnest(unit_neim) as num
	from pohod where pohod.num = ` ~ num.text ~ `
)
select
	tourist.num,
	tourist.family_name,
	tourist.given_name,
	tourist.patronymic,
	tourist.birth_year
from tourist_num
left join tourist
	on tourist.num = tourist_num.num
order by family_name, given_name`
	).getRecordSet(participantInfoRecFormat);
}

static immutable briefPohodInfoRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "mkkCode",
	string, "bookNum",
	string, "pohodRegion"
)();

JSONValue partyInfo(size_t num)
{
	import std.conv: text;
	auto pohodInfo = getCommonDB().query(`
select
	pohod.num as num,
	pohod.kod_mkk as "mkkCode",
	pohod.nomer_knigi as "bookNum",
	pohod.region_pohod as "pohodRegion"
from pohod where pohod.num = ` ~ num.text ~ `
	`).getRecordSet(briefPohodInfoRecFormat);

	JSONValue jsonResult;
	jsonResult["pohodInfo"] = pohodInfo.toStdJSON();
	jsonResult["partyList"] = getPartyList(Optional!size_t(num)).toStdJSON();

	return jsonResult;
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
	tuple("tourismKind", видТуризма, "vid"),
	tuple("complexity", категорияСложности, "ks"),
	tuple("progress", готовностьПохода, "prepar"),
	tuple("claimState", статусЗаявки, "stat")
);

//Формирует чать запроса по фильтрации походов (для SQL-секции where)
string getPohodFilterQueryPart(ref const(PohodFilter) filter)
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
		filters ~= `(array_length(links, 1) != 0 AND array_to_string(links, '', '')!= '')`;
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

import mkk_site.data_model.common: Navigation;

JSONValue getPohodList(PohodFilter filter, Navigation nav)
{
	import std.conv: text;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	string query = `select ` ~ basePohodFieldSuquery;

	if( filter.withDataCheck )
		query ~= pohodListDataCheckSubquery;
	else
		query ~= "ARRAY[]::text[] problems,\n"; // Пустой список проблем, если нет проверки данных

	query ~= pohodListFromQueryPart;

	if( filter.withFilter )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);

	nav.normalize(getPohodCount(filter));

	// Упорядочивание и страничный отбор уже делаем по готовым данным
	query ~= ` order by "beginDate" desc offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text;

	return JSONValue([
		"rs": getCommonDB().query(query).getRecordSet(pohodRecFormat).toStdJSON(),
		"nav": nav.toStdJSON()
	]);
}
