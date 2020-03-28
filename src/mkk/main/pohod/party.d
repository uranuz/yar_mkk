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
	PrimaryKey!(size_t, "num"),
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	int, "birthYear"
)();


static immutable partyQueryFormat =
`select
	%s
from pohod_party php
join tourist tr
	on tr.num = php.tourist_num
where php.pohod_num = $1::integer
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
`tr.num,
	tr.family_name,
	tr.given_name,
	tr.patronymic,
	tr.birth_year`,
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
	PrimaryKey!(size_t, "num"),
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
	enforce(num.isSet, `Невозможно получить данные, т.к. не задан номер похода`);

	auto pohodInfo = getCommonDB().queryParams(`
select
	pohod.num as num,
	pohod.mkk_code as "mkkCode",
	pohod.book_num as "bookNum",
	pohod.pohod_region as "pohodRegion"
from pohod where pohod.num = $1
	`, num).getRecordSet(briefPohodInfoRecFormat);

	auto party = getPartyList(num, Navigation());
	return typeof(return)(
		(pohodInfo && pohodInfo.length? pohodInfo[0]: null),
		party.partyList,
		party.partyNav
	);
}