module mkk_site.main_service.pohod_list;

import mkk_site.main_service.devkit;
import mkk_site.site_data;
import mkk_site.data_defs.pohod_list;

shared static this()
{
	Service.JSON_RPCRouter.join!(recentPohodList)(`pohod.recentList`);
	Service.JSON_RPCRouter.join!(getPohodEnumTypes)(`pohod.enumTypes`);
	Service.JSON_RPCRouter.join!(getPohodList)(`pohod.list`);
	Service.JSON_RPCRouter.join!(getPartyList)(`pohod.partyList`);
	Service.JSON_RPCRouter.join!(partyInfo)(`pohod.partyInfo`);
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
	pohod.num "num",
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
`;

static immutable recentPohodQuery =
`select ` ~ basePohodFieldSuquery ~ `
	marchrut "route",
	chef_coment "chiefComment"
from pohod
left join tourist chief
	on chief.num = pohod.chef_grupp
where pohod.reg_timestamp is not null
order by pohod.reg_timestamp desc nulls last
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
import std.typecons: tuple;

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

	if( filter.withDataCheck )
		filters ~=
`(
	(
		finish_date < current_date
		and prepar < 6
	) /*Поход завершён  изменить состояние подготовки*/
	OR(
		nullif(nomer_knigi, '') is not null
		and stat = 0
	) /*Присвоен номер маршрутки, не указано состояние по заявке*/
	OR(
		begin_date < current_date
		and finish_date > current_date
		and prepar != 5
	) /*Отметить, что группа на маршруте*/
	OR nullif(region_pohod, '') is null /*Не указан район похода*/
	OR nullif(marchrut, '') is null /*Не указана нитка маршрута*/
	OR vid is NULL /*Не указан вид туризма*/
	OR ks is NULL /*Не указана категория сложности*/
)`;

	if( filter.withFiles ) {
		filters ~= `(array_length(links, 1) != 0 AND array_to_string(links, '', '')!= '')`;
	}

	static immutable datePartNames = ["year", "month", "day"];
	string[] dateFilters;
	foreach( соотвПоля; соотвПолейСроков )
	{
		OptionalDate dateFilter = filter.dates.get(соотвПоля.имяВФорме, OptionalDate());

		if( dateFilter.isDefined )
		{
			dateFilters ~= ` ('` ~ Date( dateFilter.tupleof ).conv!string ~ `'::date `
				~ соотвПоля.опСравн ~ ` ` ~ соотвПоля.имяВБазе ~ `) `;
		}
		else
		{
			foreach( j, частьДаты; dateFilter.tupleof )
			{
				if( !частьДаты.isNull )
				{
					dateFilters ~= частьДаты.value.conv!string ~ ` `
						~ соотвПоля.опСравн ~ ` date_part('` ~ datePartNames[j] ~ `', ` ~ соотвПоля.имяВБазе ~ `)`;
				}
			}
		}
	}
	filters ~= dateFilters;

	if( filter.pohodRegion.length > 0 )
		filters ~= `region_pohod ILIKE '%` ~ filter.pohodRegion ~ `%'`;

	return ( filters.length > 0 ?	" ( " ~ filters.join(" ) and ( ") ~ " ) " : null );
}

import std.typecons: tuple;

static immutable pohodRecFormat = RecordFormat!(
	BasePohodFields,
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

private static immutable pohodListQueryPart = `select ` ~ basePohodFieldSuquery;

private static immutable pohodListQueryPart_data_check =
`(
	(CASE WHEN finish_date < current_date and prepar < 6
		THEN 'Поход завершён изменить состояние подготовки. <br>'
			ELSE '' END) ||
	(CASE WHEN nullif(nomer_knigi, '') is null and stat = 0
		THEN 'Присвоен номер маршрутки - не указано состояние по заявке. <br>'
			ELSE '' END) ||
	(CASE WHEN begin_date < current_date and finish_date > current_date and prepar != 5
		THEN 'Отметить, что группа на маршруте на маршруте. <br>'
			ELSE '' END) ||
	(CASE WHEN nullif(region_pohod, '') is null
		THEN 'Не указан район похода. <br>'
			ELSE '' END) ||
	(CASE WHEN nullif(marchrut, '') is null
		THEN 'Не указана нитка маршрута. <br>'
			ELSE '' END) ||
	(CASE WHEN vid is NULL
		THEN 'Не указан вид туризма. <br>'
			ELSE '' END) ||
	(CASE WHEN ks is NULL
		THEN 'Не указана категория сложности. <br>'
			ELSE '' END)
) as marchrut,
`;


private static immutable pohodListQueryPart_marchrut = ` marchrut "route",`;

private static immutable pohodListQueryPart2 =
`	prepar,
	stat
	from pohod
	left join tourist chief
		on chief.num = pohod.chef_grupp
`;

size_t getPohodCount(PohodFilter filter)
{
	import std.conv: to;
	string query = `select count(1) from pohod`;

	if( filter.withFilter )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);

	 return getCommonDB().query(query).get(0, 0, "0").to!size_t;
}

import mkk_site.data_defs.common: Navigation;

JSONValue getPohodList(PohodFilter filter, Navigation nav)
{
	import std.conv: to;
	string query = pohodListQueryPart;

	if( filter.withDataCheck )
		query ~= pohodListQueryPart_data_check;
	else
		query ~= pohodListQueryPart_marchrut;

	query ~= pohodListQueryPart2;

	if( filter.withFilter )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);

	size_t recordCount = getPohodCount(filter);
	if( recordCount < nav.offset ) {
		// Устанавливаем offset на начало последней страницы, если offset выходит за число записей
		nav.offset = (recordCount / nav.pageSize) * nav.pageSize;
	}

	query ~= ` order by pohod.begin_date desc offset ` ~ nav.offset.to!string ~ ` limit ` ~ nav.pageSize.to!string;

	JSONValue result;
	result[`nav`] = JSONValue([
		`offset`: JSONValue(nav.offset),
		`pageSize`: JSONValue(nav.pageSize),
		`recordCount`: JSONValue(recordCount)
	]);
	result["rs"] = getCommonDB().query(query).getRecordSet(pohodRecFormat).toStdJSON();

	return result;
}
