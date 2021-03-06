module mkk.main.pohod.read;

import mkk.main.devkit;
import mkk.main.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(pohodReadBase)(`pohod.readBase`);
	MainService.JSON_RPCRouter.join!(pohodRead)(`pohod.read`);

	MainService.pageRouter.joinWebFormAPI!(pohodReadBase)("/api/pohod/read_base");
	MainService.pageRouter.joinWebFormAPI!(pohodRead)("/api/pohod/read");
}

static immutable pohodInfoQueryBase =
`select
	pohod.num,
	mkk_code "mkkCode",
	book_num "bookNum",
	organization,
	party_region "partyRegion",
	begin_date "beginDate",
	finish_date "finishDate",
	tourism_kind "tourismKind",
	complexity "complexity",
	complexity_elem "complexityElem",
	pohod_region "pohodRegion",
	route "route",
	pohod.party_size "partySize",
	chief_num "chiefNum",
	alt_chief_num "altChiefNum",
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
	progress "progress",
	claim_state "claimState",
	chief_comment "chiefComment",
	"mkk_comment" "mkkComment"
from pohod
left outer join tourist chief_rec
	on pohod.chief_num = chief_rec.num
left outer join tourist alt_chief_rec
	on pohod.alt_chief_num = alt_chief_rec.num
`;

import std.typecons: tuple;
import std.datetime: Date;

static immutable pohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "mkkCode",
	string, "bookNum",
	string, "organization",
	string, "partyRegion",
	Date, "beginDate",
	Date, "finishDate",
	typeof(tourismKind), "tourismKind",
	typeof(complexity), "complexity",
	typeof(complexityElem), "complexityElem",
	string, "pohodRegion",
	string, "route",
	size_t, "partySize",
	size_t, "chiefNum",
	size_t, "altChiefNum",
	string, "chiefName",
	string, "altChiefName",
	typeof(progress), "progress",
	typeof(claimState), "claimState",
	string, "chiefComment",
	string, "mkkComment"
)(
	tuple(
		tourismKind,
		complexity,
		complexityElem,
		progress,
		claimState
	)
);

Tuple!(IBaseRecord, "pohod")
pohodReadBase(Optional!size_t pohodNum)
{
	import webtank.datctrl.detatched_record;
	import std.conv: text;

	if( pohodNum.isNull ) {
		return typeof(return)(makeMemoryRecord(pohodRecFormat));
	}

	auto rs = getCommonDB().query(
		pohodInfoQueryBase ~ ` where pohod.num = ` ~ pohodNum.text
	).getRecordSet(pohodRecFormat);

	if( rs && rs.length == 1 ) {
		return typeof(return)(rs[0]);
	}
	return typeof(return)();
}

import mkk.common.utils: getAuthRedirectURI;
import mkk.main.pohod.party: getPartyList;

Tuple!(
	IBaseRecord, "pohod",
	IBaseRecordSet, "extraFileLinks",
	IBaseRecordSet, "partyList",
	Navigation, "partyNav",
	string, "authRedirectURI"
)
pohodRead(HTTPContext ctx, Optional!size_t num)
{
	auto party = getPartyList(num, Navigation());
	return typeof(return)(
		pohodReadBase(num).pohod,
		getExtraFileLinks(num),
		party.partyList,
		party.partyNav,
		getAuthRedirectURI(ctx)
	);
}

static immutable pohodFileLinkRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "name",
	string, "link"
)();

IBaseRecordSet getExtraFileLinks(Optional!size_t num)
{
	import std.conv: text;
	return getCommonDB().query(
		`select num, name, link as num from pohod_file_link where pohod_num = ` ~ (num.isSet? num.text: `null::integer`)
	).getRecordSet(pohodFileLinkRecFormat);
}

import std.json: JSONValue;

JSONValue renderExtraFileLinks(Optional!size_t num, string extraFileLinks, string instanceName)
{
	import std.json: JSONValue, JSONType, parseJSON;
	import std.conv: to;
	import std.base64: Base64;
	import webtank.common.optional: Optional;

	JSONValue dataDict;
	if( num.isSet ) {
		// Если есть ключ похода, то берем ссылки из похода
		dataDict["linkList"] = getExtraFileLinks(num).toStdJSON();
	} else {
		// Иначе отрисуем список ссылок, который нам передали
		string decodedExtraFileLinks = cast(string) Base64.decode(extraFileLinks);
		JSONValue jExtraFileLinks = parseJSON(decodedExtraFileLinks);
		if( jExtraFileLinks.type != JSONType.array && jExtraFileLinks.type != JSONType.null_  ) {
			throw new Exception(`Некорректный формат списка ссылок на доп. материалы`);
		}

		JSONValue[] linkList;
		if( jExtraFileLinks.type == JSONType.array ) {
			linkList.length = jExtraFileLinks.array.length;
			foreach( size_t i, ref JSONValue entry; jExtraFileLinks ) {
				if( entry.type != JSONType.array || entry.array.length < 2) {
					throw new Exception(`Некорректный формат элемента списка ссылок на доп. материалы`);
				}
				if( entry[0].type != JSONType.string && entry[0].type != JSONType.null_ ) {
					throw new Exception(`Некорректный формат описания ссылки на доп. материалы`);
				}
				if( entry[1].type != JSONType.string && entry[1].type != JSONType.null_ ) {
					throw new Exception(`Некорректный формат ссылки на доп. материалы`);
				}
				linkList[i] = [
					(entry[0].type == JSONType.string? entry[0].str : null),
					(entry[1].type == JSONType.string? entry[1].str : null)
				];
			}
		}
		dataDict["linkList"] = linkList;
	}
	dataDict["instanceName"] = instanceName;

	return dataDict;
}