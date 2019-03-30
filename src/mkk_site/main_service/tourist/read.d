module mkk_site.main_service.tourist.read;

import mkk_site.main_service.devkit;
import mkk_site.data_model.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(readTourist)(`tourist.read`);

	MainService.pageRouter.joinWebFormAPI!(readTourist)("/api/tourist/read");
}

import std.typecons: Tuple, tuple;

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
	typeof(sportsCategory), "sportsCategory",
	typeof(refereeCategory), "refereeCategory",
	string, "phone",
	bool, "showPhone",
	string, "email",
	bool, "showEmail",
	string, "comment"
)(
	null,
	tuple(
		sportsCategory,
		refereeCategory
	)
);

Tuple!(IBaseRecord, "tourist")
readTourist(HTTPContext ctx, Optional!size_t num)
{
	import std.conv: text;
	import webtank.datctrl.detatched_record;

	if( num.isNull ) {
		return typeof(return)(makeMemoryRecord(touristRecFormat));
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
		where num = ` ~ num.text
	).getRecordSet(touristRecFormat);

	if( rs && rs.length == 1 ) {
		return typeof(return)(rs[0]);
	}
	return typeof(return)();
}