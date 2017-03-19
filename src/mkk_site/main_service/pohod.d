module mkk_site.main_service.pohod;

import mkk_site.main_service.devkit;
import mkk_site.site_data;

shared static this()
{
	Service.JSON_RPCRouter.join!(recentPohodList)(`pohod.recentList`);
	Service.JSON_RPCRouter.join!(getPohodEnumTypes)(`pohod.enumTypes`);
}

import std.datetime: Date;
import std.typecons: tuple;

static immutable recentPohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "Ключ",
	string, "Номер книги",
	Date, "Дата начала",
	Date, "Дата конца",
	typeof(видТуризма), "Вид",
	typeof(категорияСложности), "КС",
	typeof(элементыКС), "Элем КС",
	string, "Район",
	size_t, "Ключ рук",
	string, "Фамилия рук",
	string, "Имя рук",
	string, "Отчество рук",
	string, "Организация",
	string, "Маршрут",
	string, "Коментарий рук",
)(
	null,
	tuple(
		видТуризма,
		категорияСложности,
		элементыКС
	)
);
	
static immutable recentPohodQuery =
`select
	pohod.num as "Ключ",
	(
		coalesce(kod_mkk, '000-00') || ' ' ||
		coalesce(nomer_knigi, '00-00')
	) as "Номер книги",
	begin_date as "Дата начала",
	finish_date as "Дата конца",
	vid as "Вид",
	ks as "КС",
	elem as "Элем КС",
	region_pohod as "Район",
	chef.num as "Ключ рук",
	chef.family_name as "Фамилия рук",
	chef.given_name as "Имя рук",
	chef.patronymic as "Отчество рук",
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as "Организация",
	( coalesce(marchrut, '') ) as "Маршрут",
	( coalesce(chef_coment, '') ) as "Коментарий рук"
from pohod 
left join tourist as chef
on chef.num = pohod.chef_grupp
where pohod.reg_timestamp is not null
order by pohod.reg_timestamp desc
limit 10
`;

auto recentPohodList()
{
	return getCommonDB()
		.query(recentPohodQuery)
		.getRecordSet(recentPohodRecFormat);
}

import std.json: JSONValue;
JSONValue getPohodEnumTypes()
{
	JSONValue jResult;
	jResult[`vid`] = видТуризма.getStdJSON();
	jResult[`ks`] = категорияСложности.getStdJSON();
	jResult[`prepar`] = готовностьПохода.getStdJSON();
	jResult[`stat`] = статусЗаявки.getStdJSON();

	return jResult;
}