module mkk.main.pohod.party;

import mkk.main.devkit;

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


static immutable partyQueryFormat =
`select
	%s
from(
	select distinct unnest(unit_neim) as num
	from pohod where pohod.num = $1
) as tourist_num
join tourist
	on tourist.num = tourist_num.num
%s
`;

Tuple!(
	IBaseRecordSet, `partyList`,
	Navigation, `partyNav`
) getPartyList(Optional!size_t num, Navigation nav)
{
	import webtank.datctrl.record_set;
	import std.conv: text;
	import std.format: format;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10);

	if( num.isNull ) {
		return typeof(return)(makeMemoryRecordSet(participantInfoRecFormat), nav);
	}
	string mainQuery = partyQueryFormat.format(
`tourist.num,
	tourist.family_name,
	tourist.given_name,
	tourist.patronymic,
	tourist.birth_year`,
`order by family_name, given_name
offset $2 limit $3`);

	string countQuery = partyQueryFormat.format(`count(1)`, ``);

	nav.recordCount = getCommonDB().queryParams(countQuery, num).getScalar!size_t();

	return typeof(return)(
		getCommonDB().queryParams(
			mainQuery, num, nav.offset, nav.recordCount
		).getRecordSet(participantInfoRecFormat),
		nav
	);
}

static immutable briefPohodInfoRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "mkkCode",
	string, "bookNum",
	string, "pohodRegion"
)();

Tuple!(
	IBaseRecord, `pohodInfo`,
	IBaseRecordSet, `partyList`,
	Navigation, `partyNav`
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

	auto party = getPartyList(num, Navigation());
	return typeof(return)(
		(pohodInfo && pohodInfo.length? pohodInfo[0]: null),
		party.partyList,
		party.partyNav
	);
}