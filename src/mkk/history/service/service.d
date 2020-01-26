module mkk.history.service.service;

import webtank.ivy.backend_service: IvyBackendService;
import mkk.common.service: Service;

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
IvyBackendService HistoryService() @property
{
	IvyBackendService srv = cast(IvyBackendService) Service();
	assert(srv, `View service is null`);
	return srv;
}

shared static this() {
	Service(new IvyBackendService("yarMKKHistory"));
}
