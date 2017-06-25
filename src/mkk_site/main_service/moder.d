module mkk_site.main_service.moder;
import mkk_site.main_service.devkit;

shared static this()
{
	Service.JSON_RPCRouter.join!(moderList)(`moder.list`);
}

/// Формат записи для списка модераторов сайта
static immutable moderListRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "name",
	string, "status",
	string, "region",
	string, "email",
	string, "contact_info",
	size_t, "tourist_num"
)();
	
static immutable moderListQuery =
`select num, name, status, region, email, contact_info, tourist_num
from site_user where "user_group" in ('moder', 'admin')
order by name
;`;

auto moderList()
{
	return getAuthDB()
		.query(moderListQuery)
		.getRecordSet(moderListRecFormat);
}