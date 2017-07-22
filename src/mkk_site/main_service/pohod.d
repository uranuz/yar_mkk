module mkk_site.main_service.pohod;

import mkk_site.main_service.devkit;
import mkk_site.site_data;

shared static this()
{
	Service.JSON_RPCRouter.join!(recentPohodList)(`pohod.recentList`);
	Service.JSON_RPCRouter.join!(getPohodEnumTypes)(`pohod.enumTypes`);
	Service.JSON_RPCRouter.join!(getPohodList)(`pohod.list`);
	Service.JSON_RPCRouter.join!(getPohodCount)(`pohod.listSize`);
	Service.JSON_RPCRouter.join!(getPartyList)(`pohod.partyList`);
	Service.JSON_RPCRouter.join!(partyInfo)(`pohod.partyInfo`);
}

import std.datetime: Date;
import std.typecons: tuple;

static immutable recentPohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
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
	string, "organization",
	string, "route",
	string, "chiefComment"
)(
	null,
	tuple(
		видТуризма,
		категорияСложности,
		элементыКС
	)
);
	
static immutable recentPohodQuery =
`select
	pohod.num as "num",
	(
		coalesce(kod_mkk, '000-00') || ' ' ||
		coalesce(nomer_knigi, '00-00')
	) as "bookNum",
	begin_date as "beginDate",
	finish_date as "finishDate",
	vid as "tourismKind",
	ks as "complexity",
	elem as "complexityElems",
	region_pohod as "pohodRegion",
	chef.num as "chiefNum",
	chef.family_name as "chiefFamilyName",
	chef.given_name as "chiefGivenName",
	chef.patronymic as "chiefPatronymic",
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as "organization",
	( coalesce(marchrut, '') ) as "route",
	( coalesce(chef_coment, '') ) as "chiefComment"
from pohod
left join tourist as chef
	on chef.num = pohod.chef_grupp
where pohod.reg_timestamp is not null
order by pohod.reg_timestamp desc nulls last
limit 10
`;

/// Возвращает список последних добавленных походов
auto recentPohodList()
{
	return getCommonDB()
		.query(recentPohodQuery)
		.getRecordSet(recentPohodRecFormat);
}

import std.json: JSONValue;
/**
 * Возвращает JSON с перечислимыми типами, относящимися к походу
 */
JSONValue getPohodEnumTypes()
{
	JSONValue jResult;
	jResult[`tourismKind`] = видТуризма.toStdJSON();
	jResult[`complexity`] = категорияСложности.toStdJSON();
	jResult[`progress`] = готовностьПохода.toStdJSON();
	jResult[`claimState`] = статусЗаявки.toStdJSON();

	return jResult;
}

static immutable participantInfoRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	int, "birthYear"
)();

auto getPartyList(size_t num)
{
	import std.conv: text;
	return getCommonDB().query(`
with tourist_num as (
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
	`).getRecordSet(participantInfoRecFormat);
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
	jsonResult["partyList"] = getPartyList(num).toStdJSON();

	return jsonResult;
}

/// Структура фильтра по походам
struct PohodFilter
{
	int[] tourismKinds; /// Виды туризма
	int[] complexities; /// Категории сложности
	int[] progress; /// Фазы прохождения похода
	int[] claimStates; /// Состояния заявок
	OptionalDate[string] dates; /// Фильтр по датам
	string pohodRegion; /// Регион проведения похода
	bool withFiles; /// Записи с доп. материалами
	bool withDataCheck; /// Режим проверки данных

	/// Проверка, что есть какая-либо фильтрация
	bool withFilter() @property
	{
		import std.algorithm: canFind;

		if( tourismKinds.length > 0 || complexities.length > 0 || 
			progress.length > 0 || claimStates.length > 0 ||
			pohodRegion.length > 0 || withFiles || withDataCheck
		) return true;

		foreach( fieldName, date; this.dates )
		{
			// Второе условие на проверку того, что переданное поле даты есть в наборе
			if( !date.isNull && соотвПолейСроков.canFind!( (x, y)=> x.имяВФорме == y )(fieldName) )
				return true;
		}
		return false;
	}
}

struct СоотвПолейСроков {
	string имяВФорме;
	string имяВБазе;
	string опСравн;
};
	
//Вспомогательный массив структур для составления запроса
//Устанавливает соответствие между полями в форме и в базе
//и операциями сравнения, которые будут в запросе
static immutable СоотвПолейСроков[] соотвПолейСроков = [
	{ "beginDateRangeHead", "begin_date", "<=" },
	{ "beginDateRangeTail", "begin_date", ">=" },
	{ "endDateRangeHead", "finish_date", "<=" },
	{ "endDateRangeTail", "finish_date", ">=" }
];

import std.meta: AliasSeq;
import std.typecons: tuple;

// Просто список кортежей, который позволяет установить соответствие между тремя полями
// 0: название поля фильтрации в параметрах метода
// 1: формат перечислимого типа для этого параметра
// 2: соответствующее название поля в структуре ФильтрПоходов
alias PohodEnumFields = AliasSeq!(
	tuple("tourismKinds", видТуризма),
	tuple("complexities", категорияСложности),
	tuple("progress", готовностьПохода),
	tuple("claimStates", статусЗаявки)
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
			filters ~= "` ~ enumSpec[0] ~ ` in(" ~ filter.` ~ enumSpec[0] ~ `.conv!(string[]).join(", ") ~ ")";
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
	PrimaryKey!(size_t), "num",
	string, "bookNum",
	string, "dateRange",
	typeof(видТуризма), "tourismKind",
	typeof(категорияСложности), "complexity",
	typeof(элементыКС), "complexityElems",
	string, "pohodRegion",
	string, "chiefName",
	string, "partySize",
	string, "organization",
	string, "route",
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

private static immutable pohodListQueryPart =
`with
t_chef as (
	select 
		pohod.num,
		(
			coalesce(T.family_name,'нет данных')||'<br> '
			||coalesce(T.given_name,'')||'<br> '
			||coalesce(T.patronymic,'')||'<br>'
			||coalesce(T.birth_year::text,'')
		) as fio

	from pohod
	LEFT join tourist T
		on pohod.chef_grupp = T.num
)

select
	pohod.num,
	( coalesce(kod_mkk,'000-00') || '<br>' || coalesce(nomer_knigi, '00-00') ) as nomer_knigi,
	(
		date_part('day', begin_date) || '.' ||
		date_part('month', begin_date) || '.' ||
		date_part('YEAR', begin_date) 
		||' <br> '||
		date_part('day', finish_date) || '.' ||
		date_part('month', finish_date) || '.' ||
		date_part('YEAR', finish_date)
	) as dat,
	vid,
	ks,
	elem,
	region_pohod,
	t_chef.fio,
	( coalesce(pohod.unit, '') ) as kol_tur,
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as organiz,
`;
	
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
	
	
private static immutable pohodListQueryPart_marchrut = "('Нитка маршрута: ' || coalesce(marchrut::text, '') ) as marchrut,";

private static immutable pohodListQueryPart2 =
`	prepar, stat
	from pohod
	LEFT OUTER JOIN t_chef
		on t_chef.num = pohod.num
`;

size_t getPohodCount(PohodFilter filter)
{
	import std.conv: to;
	string query = `select count(1) from pohod`;
	
	if( filter.withFilter )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);
	
	 return getCommonDB()
		.query(query)
		.get(0, 0, "0").to!size_t;
}

struct Navigation
{
	size_t offset = 0;
	size_t pageSize = 20;
}

auto getPohodList(PohodFilter filter, Navigation nav)
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

	query ~= ` order by pohod.begin_date desc offset ` ~ nav.offset.to!string ~ ` limit ` ~ nav.pageSize.to!string;

	return getCommonDB()
		.query(query)
		.getRecordSet(pohodRecFormat);
}
