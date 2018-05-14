module mkk_site.common.service;

import webtank.net.service.iface: IWebService;

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
IWebService Service() @property
{
	assert(_mkk_service, `MKK service is not initialized!`);
	return _mkk_service;
}

// Инициализация ссылки на сервис (устанавливается только 1 раз)
void Service(IWebService service) @property
{
	assert(!_mkk_service, `MKK service is already initialized!`);
	_mkk_service = service;
}

string endpoint(string serviceName, string endpointName = `default`) {
	return Service.endpoint(serviceName, endpointName);
}

// Service is process singleton object
private __gshared IWebService _mkk_service;