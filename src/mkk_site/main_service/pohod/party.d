module mkk_site.main_service.pohod.party;

import mkk_site.main_service.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getPartyList)(`pohod.partyList`);
	MainService.JSON_RPCRouter.join!(partyInfo)(`pohod.partyInfo`);

	MainService.pageRouter.joinWebFormAPI!(getPartyList)("/api/pohod/partyList");
	MainService.pageRouter.joinWebFormAPI!(partyInfo)("/api/pohod/partyInfo");
}

static immutable participantInfoRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	int, "birthYear"
)();

Tuple!(IBaseRecordSet, `partyList`) getPartyList(Optional!size_t num)
{
	import webtank.datctrl.record_set;
	import std.conv: text;
	if( num.isNull ) {
		return typeof(return)(makeMemoryRecordSet(participantInfoRecFormat));
	}

	return typeof(return)(getCommonDB().query(
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
join tourist
	on tourist.num = tourist_num.num
order by family_name, given_name`
	).getRecordSet(participantInfoRecFormat));
}

static immutable briefPohodInfoRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "mkkCode",
	string, "bookNum",
	string, "pohodRegion"
)();

Tuple!(
	IBaseRecord, `pohodInfo`,
	IBaseRecordSet, `partyList`
)
partyInfo(Optional!size_t num)
{
	import std.conv: text;
	import std.exception: enforce;

	enforce(num.isSet, `Невозможно получить данные, т.к. не задан номер похода`);

	auto pohodInfo = getCommonDB().query(`
select
	pohod.num as num,
	pohod.kod_mkk as "mkkCode",
	pohod.nomer_knigi as "bookNum",
	pohod.region_pohod as "pohodRegion"
from pohod where pohod.num = ` ~ num.text ~ `
	`).getRecordSet(briefPohodInfoRecFormat);

	return typeof(return)(
		(pohodInfo && pohodInfo.length? pohodInfo[0]: null),
		getPartyList(num).partyList
	);
}