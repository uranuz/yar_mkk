module mkk_site.main_service.moder;

import mkk_site.main_service.devkit;

shared static this()
{
	Service.JSON_RPCRouter.join!(moderList)(`moder.list`);
	Service.JSON_RPCRouter.join!(testMethod)(`test.testMethod`);
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

struct TestFilter
{
	size_t id;
	string name;
	double price;
	private size_t _testInt;
	void testInt(size_t value) @property {
		_testInt = value;
	}
	size_t testInt() @property {
		return _testInt;
	}
}

auto testMethod(TestFilter filter)
{
	return filter;
}