module mkk.main.tourist.experience;

import mkk.main.devkit;

import mkk.main.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getExperience)(`tourist.experience`);

	MainService.pageRouter.joinWebFormAPI!(getExperience)("/api/tourist/experience");
}

import std.datetime: Date;

// данные о походах туриста
static immutable pohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t, "num"),
	string, "mkkCode",
	string, "bookNum",
	Date, "beginDate",
	Date, "finishDate",
	typeof(tourismKind), "tourismKind",
	typeof(complexity), "complexity",
	typeof(complexityElem), "complexityElem",
	size_t, "chiefNum",
	string, "partyRegion",
	string, "organization",
	string, "pohodRegion",
	string, "route",
	typeof(progress), "progress",
	typeof(claimState), "claimState"
)(
	tuple(
		tourismKind,
		complexity,
		complexityElem,
		progress,
		claimState
	)
);

Tuple!(
	IBaseRecord, "tourist",
	IBaseRecordSet, "pohodList",
	Navigation, "nav"
)
getExperience(
	HTTPContext context,
	Optional!size_t num,
	Navigation nav
) {
	import mkk.main.tourist.read: readTourist;
	enforce(num.isSet, `Невозможно отобразить данные туриста. Номер туриста не задан`);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	// Получаем запись туриста
	auto touristRes = readTourist(context, num);
	if( !touristRes.tourist ) {
		return typeof(return)(); // Данных о туристе нет - возвращаем пустой кортеж
	}

	// Получаем количество походов туриста
	size_t pohodCount = getCommonDB().queryParams(
		`select count(1) from pohod_party php where php.tourist_num = $1::integer`, num
	).getScalar!size_t();

	nav.normalize(pohodCount);

	auto pohodList = getCommonDB().queryParams(
`select
	ph.num,
	ph.mkk_code "mkkCode",
	ph.book_num "bookNum",
	ph.begin_date "beginDate",
	ph.finish_date "finishDate",
	ph.tourism_kind as "tourismKind",
	ph.complexity as "complexity",
	ph.complexity_elem as "complexityElem",
	ph.chief_num "chiefNum",
	ph.party_region "partyRegion",
	ph.organization,
	ph.pohod_region "pohodRegion",
	ph.route "route",
	ph.progress "progress",
	ph.claim_state "claimState"
from pohod_party php
join pohod ph
	on ph.num = php.pohod_num
where php.tourist_num = $1::integer
order by begin_date desc
offset $2 limit $3`,
	num, nav.offset, nav.pageSize
	).getRecordSet(pohodRecFormat);

	return typeof(return)(touristRes.tourist, pohodList, nav);
}



