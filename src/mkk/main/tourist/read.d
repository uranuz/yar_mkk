module mkk.main.tourist.read;

import mkk.main.devkit;
import mkk.main.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(readTourist)(`tourist.read`);

	MainService.pageRouter.joinWebFormAPI!(readTourist)("/api/tourist/read");
}

//получаем данные о ФИО и г.р. туриста
static immutable touristRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	size_t, "birthYear",
	ubyte, "birthMonth",
	ubyte, "birthDay",
	string, "address",
	string, "experience",
	typeof(sportCategory), "sportCategory",
	typeof(refereeCategory), "refereeCategory",
	string, "phone",
	bool, "showPhone",
	string, "email",
	bool, "showEmail",
	string, "comment"
)(
	null,
	tuple(
		sportCategory,
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
		` ~ (ctx.rights.hasRight(`tourist.item.address`, `edit`)? `address`: `null::text`) ~ `,
		experience "experience",
		sport_category "sportCategory",
		referee_category "refereeCategory",
		case when ` ~ (ctx.rights.hasRight(`tourist.item.phone`, `edit`)? `true`: `show_phone`) ~ `
			then phone else null end "phone",
		show_phone "showPhone",
		case when ` ~ (ctx.rights.hasRight(`tourist.item.email`, `edit`)? `true`: `show_email`) ~ `
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