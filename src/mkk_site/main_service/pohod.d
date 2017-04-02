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
	PrimaryKey!(size_t), "num",
	string, "bookNum",
	Date, "beginDate",
	Date, "finishDate",
	typeof(видТуризма), "vid",
	typeof(категорияСложности), "ks",
	typeof(элементыКС), "ksElem",
	string, "region",
	size_t, "chiefNum",
	string, "chiefFamilyName",
	string, "chiefGivenName",
	string, "chiefPatronymic",
	string, "organization",
	string, "route",
	string, "chiefComment",
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
	pohod.num as "num",
	(
		coalesce(kod_mkk, '000-00') || ' ' ||
		coalesce(nomer_knigi, '00-00')
	) as "bookNum",
	begin_date as "beginDate",
	finish_date as "finishDate",
	vid as "vid",
	ks as "ks",
	elem as "ksElem",
	region_pohod as "region",
	chef.num as "chiefNum",
	chef.family_name as "chiefFamilyName",
	chef.given_name as "chiefGivenName",
	chef.patronymic as "chiefPatronymic",
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as "organization",
	( coalesce(marchrut, '') ) as "route",
	( coalesce(chef_coment, '') ) as "chiefComment"
from pohod
left join tourist as chef
	on chef.num = pohod.chef_grupp
where pohod.reg_timestamp is not null
order by pohod.reg_timestamp desc nulls last
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