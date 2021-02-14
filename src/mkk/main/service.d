module mkk.main.service;

import webtank.ivy.service.main: IvyMainService;
import mkk.common.service: Service;

shared static this()
{
	Service(new IvyMainService("yarMKKMain"));
}

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
IvyMainService MainService() @property
{
	IvyMainService srv = cast(IvyMainService) Service();
	assert(srv, `View service is null`);
	return srv;
}