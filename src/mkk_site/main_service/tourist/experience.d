module mkk_site.main_service.tourist.experience;

import mkk_site.main_service.devkit;
import mkk_site.data_model.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getExperience)(`tourist.experience`);

	MainService.pageRouter.joinWebFormAPI!(getExperience)("/api/tourist/experience");
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


import std.typecons: Tuple;
import mkk_site.data_model.common: Navigation;

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
	import mkk_site.main_service.tourist.read: readTourist;
	import std.conv: to, text;
	import std.exception: enforce;
	enforce(num.isSet, `Невозможно отобразить данные туриста. Номер туриста не задан`);

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	// Получаем запись туриста
	auto touristRes = readTourist(context, num);
	if( !touristRes.tourist ) {
		return typeof(return)(); // Данных о туристе нет - возвращаем пустой кортеж
	}

	// Получаем количество походов туриста
	size_t pohodCount = getCommonDB().query(
		`select count(1) from pohod where `~ num.text ~ ` = any(unit_neim)`
	).get(0, 0, "0").to!size_t;

	nav.normalize(pohodCount);

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
where ` ~ num.text ~ ` = any(unit_neim)
order by begin_date desc
offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text
	).getRecordSet(pohodRecFormat);

	return typeof(return)(touristRes.tourist, pohodList, nav);
}



