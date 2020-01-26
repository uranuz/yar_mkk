module mkk.main.service;

import webtank.ivy.main_service: IvyMainService;
import mkk.common.service: Service;

shared static this()
{
	import webtank.ivy.main_service: IvyMainService;
	Service(new IvyMainService("yarMKKMain"));
}

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
IvyMainService MainService() @property
{
	IvyMainService srv = cast(IvyMainService) Service();
	assert(srv, `View service is null`);
	return srv;
}