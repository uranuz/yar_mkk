module mkk_site.main_service.experience;
import mkk_site.main_service.devkit;
import mkk_site.data_model.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getExperience)(`tourist.experience`);
	MainService.JSON_RPCRouter.join!(getTourist)(`tourist.read`);
}

import std.typecons: tuple;
import std.datetime: Date;

// данные о походах туриста
static immutable pohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "mkkCode",
	string, "bookNum",
	Date, "beginDate",
	Date, "finishDate",
	typeof(видТуризма), "tourismKind",
	typeof(категорияСложности), "complexity",
	typeof(элементыКС), "complexityElems",
	size_t, "chiefNum",
	string, "partyRegion",
	string, "organization",
	string, "pohodRegion",
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


import std.json: JSONValue;
import mkk_site.data_model.common: Navigation;
import webtank.common.std_json.to: toStdJSON;

JSONValue getExperience(
	HTTPContext context,
	size_t touristKey,
	Navigation nav
) {
	import std.conv: to, text;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	// Получаем запись туриста
	auto touristRec = getTourist(context, Optional!size_t(touristKey));
	if( !touristRec ) {
		return JSONValue();
	}

	// Получаем количество походов туриста
	size_t pohodCount = getCommonDB().query(
		`select count(1) from pohod where `~ touristKey.text ~ ` = any(unit_neim)`
	).get(0, 0, "0").to!size_t;

	nav.normalize(pohodCount);

	// Походы туриста - основная таблица
	auto pohodList = getCommonDB().query(
`select
	num,
	kod_mkk "mkkCode",
	nomer_knigi "bookNum",
	begin_date "beginDate",
	finish_date "finishDate",
	vid as "tourismKind",
	ks as "complexity",
	elem as "complexityElems",
	chef_grupp "chiefNum",
	region_group "partyRegion",
	organization,
	region_pohod "pohodRegion",
	marchrut "route",
	prepar "progress",
	stat "claimState"
from pohod
where ` ~ touristKey.text ~ ` = any(unit_neim)
order by begin_date desc
offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text
	).getRecordSet(pohodRecFormat);

	// Сборка из всех данных
	return JSONValue([
		"tourist": touristRec.toStdJSON(),
		"pohodList": pohodList.toStdJSON(),
		"nav": nav.toStdJSON()
	]);
}

//получаем данные о ФИО и г.р. туриста
static immutable touristRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	size_t, "birthYear",
	ubyte, "birthMonth",
	ubyte, "birthDay",
	string, "address",
	string, "experience",
	typeof(спортивныйРазряд), "sportsCategory",
	typeof(судейскаяКатегория), "refereeCategory",
	string, "phone",
	bool, "showPhone",
	string, "email",
	bool, "showEmail",
	string, "comment"
)(
	null,
	tuple(
		спортивныйРазряд,
		судейскаяКатегория
	)
);

IBaseRecord getTourist(HTTPContext ctx, Optional!size_t touristNum)
{
	import std.conv: text;
	import webtank.datctrl.detatched_record;

	if( touristNum.isNull ) {
		return makeMemoryRecord(touristRecFormat);
	}

	auto rs = getCommonDB().query(
	`select
		num,
		family_name "familyName",
		given_name "givenName",
		patronymic,
		birth_year "birthYear",
		-- Разбор даты рождения на месяц и день.
		-- select здесь необходим, иначе запись не отбирается, если поле birth_date не соответствует шаблону
		(select (regexp_matches("birth_date", '(\d*)[.,](\d+)'))[2])::integer "birthMonth",
		(select (regexp_matches("birth_date", '(\d+)[.,](\d*)'))[1])::integer "birthDay",
		` ~ (ctx.rights.hasRight(`tourist.item.address`, `forcedRead`)? `address`: `null::text`) ~ `,
		exp "experience",
		razr "sportsCategory",
		sud "refereeCategory",
		case when ` ~ (ctx.rights.hasRight(`tourist.item.phone`, `forcedRead`)? `true`: `show_phone`) ~ `
			then phone else null end "phone",
		show_phone "showPhone",
		case when ` ~ (ctx.rights.hasRight(`tourist.item.email`, `forcedRead`)? `true`: `show_email`) ~ `
			then email else null end "email",
		show_email "showEmail",
		comment
	from tourist
		where num = ` ~ touristNum.text
	).getRecordSet(touristRecFormat);

	if( rs && rs.length == 1 ) {
		return rs[0];
	}
	return null;
}
