module mkk_site.main_service.moder;
import mkk_site.main_service.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(moderList)(`moder.list`);
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
`select
	su.num,
	su.name,
	su.status,
	su.region,
	su.email,
	su.contact_info,
	su.tourist_num
from access_role ar
join user_access_role uar
	on uar.role_num = ar.num
join site_user su
	on su.num = uar.user_num
where ar.name in ('moder', 'admin')
	and su.is_blocked is not true
order by name
`;

auto moderList() {
	return getAuthDB().query(moderListQuery).getRecordSet(moderListRecFormat);
}