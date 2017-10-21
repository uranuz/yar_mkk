module mkk_site.main_service.pohod_read;

import mkk_site.main_service.devkit;
import mkk_site.site_data;

shared static this()
{
	Service.JSON_RPCRouter.join!(readPohod)(`pohod.read`);
	Service.JSON_RPCRouter.join!(getExtraFileLinks)(`pohod.extraFileLinks`);
}

static immutable pohodInfoQueryBase =
`select
	pohod.num,
	kod_mkk "mkkCode",
	nomer_knigi "bookNum",
	organization,
	region_group "partyRegion",
	begin_date "beginDate",
	finish_date "finishDate",
	vid "tourismKind",
	ks "complexity",
	elem "complexityElems",
	region_pohod "pohodRegion",
	marchrut "route",
	pohod.unit "partySize",
	chef_grupp "chiefNum",
	alt_chef "altChiefNum",
	case
		when
			chief_rec.family_name is null
			and chief_rec.given_name is null
			and chief_rec.patronymic is null
		then
				'нет данных'
		else
			coalesce(chief_rec.family_name, '')
			|| coalesce(' ' || chief_rec.given_name,'')
			|| coalesce(' ' || chief_rec.patronymic,'')
			|| coalesce(' ' || chief_rec.birth_year::text,'')
	end "chiefName",
	case
		when
			alt_chief_rec.family_name is null
			and alt_chief_rec.given_name is null
			and alt_chief_rec.patronymic is null
		then
			'нет'
		else
			coalesce(alt_chief_rec.family_name, '')
			|| coalesce(' ' || alt_chief_rec.given_name,'')
			|| coalesce(' ' || alt_chief_rec.patronymic,'')
			|| coalesce(' ' || alt_chief_rec.birth_year::text,'')
	end "altChiefName",
	prepar "progress",
	stat "claimState",
	chef_coment "chiefComment",
	"MKK_coment" "mkkComment"
from pohod
left outer join tourist chief_rec
	on pohod.chef_grupp = chief_rec.num
left outer join tourist alt_chief_rec
	on pohod.alt_chef = alt_chief_rec.num
`;

import std.typecons: tuple;
import std.datetime: Date;

static immutable pohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "mkkCode",
	string, "bookNum",
	string, "organization",
	string, "partyRegion",
	Date, "beginDate",
	Date, "finishDate",
	typeof(видТуризма), "tourismKind",
	typeof(категорияСложности), "complexity",
	typeof(элементыКС), "complexityElems",
	string, "pohodRegion",
	string, "route",
	size_t, "partySize",
	size_t, "chiefNum",
	size_t, "altChiefNum",
	string, "chiefName",
	string, "altChiefName",
	typeof(готовностьПохода), "progress",
	typeof(статусЗаявки), "claimState",
	string, "chiefComment",
	string, "mkkComment"
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

IBaseRecord readPohod(Optional!size_t pohodNum)
{
	import webtank.datctrl.detatched_record;
	import std.conv: text;

	if( pohodNum.isNull ) {
		return makeMemoryRecord(pohodRecFormat);
	}

	auto rs = getCommonDB().query(
		pohodInfoQueryBase ~ ` where pohod.num = ` ~ pohodNum.text
	).getRecordSet(pohodRecFormat);

	if( rs && rs.length == 1 ) {
		return rs[0];
	}
	return null;
}

static immutable extraFileLinkRecordFormat = RecordFormat!(
	PrimaryKey!string, "linkData"
)();

import std.typecons: Tuple;

alias ExtraFileLink = Tuple!( string, "uri", string, "descr" );

auto getExtraFileLinks(Optional!size_t num)
{
	import std.conv: text;
	ExtraFileLink[] links;
	if( num.isNull ) {
		return links;
	}

	auto rs = getCommonDB().query(
		`select unnest(links) as num from pohod where pohod.num = ` ~ num.text
	).getRecordSet(extraFileLinkRecordFormat);

	links.length = rs.length;
	size_t i = 0;
	foreach( rec; rs )
	{
		string[] linkPair = parseExtraFileLink(rec.get!"linkData"());
		links[i].uri = linkPair[0];
		links[i].descr = linkPair[1];

		++i;
	}

	return links;
}