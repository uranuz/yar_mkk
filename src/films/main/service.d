module films.main.service;

import webtank.net.service.json_rpc_service: JSON_RPCService;
import mkk.common.service;
import webtank.ivy.service_mixin: IvyServiceMixin, IIvyServiceMixin;

class FilmsMainService: JSON_RPCService, IIvyServiceMixin
{
	import webtank.security.access_control: IAccessController;
	import webtank.security.right.iface.controller: IRightController;

	mixin IvyServiceMixin;

	this(string serviceName)
	{
		super(serviceName);

		_startIvyLogging();
		_initTemplateCache();
	}

	override IAccessController accessController() @property
	{
		assert(false, `Access controller is null`);
	}

	override IRightController rightController() @property
	{
		assert(false, `Right controller is null`);
	}
}

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
FilmsMainService MainService() @property
{
	FilmsMainService srv = cast(FilmsMainService) Service();
	assert( srv, `View service is null` );
	return srv;
}

// Метод для получения экземпляра объекта подключения к основной БД сервиса МКК
IDatabase getCommonDB() @property
{
	assert( _commonDB, `MKK main service common DB connection is not initialized!` );
	return _commonDB;
}

shared static this()
{
	Service(new FilmsMainService("filmsMain"));
}

import webtank.db.database: IDatabase;

// Each thread uses it's own thread local instance of connection to database,
// because PostgreSQL connection is not thread safe
private IDatabase _commonDB;

static this()
{
	import webtank.net.service.config: getServiceDatabases;
	import webtank.db.postgresql: DBPostgreSQL;

	_commonDB = new DBPostgreSQL(MainService.dbConnStrings["commonDB"], &MainService.databaseLogerMethod);
}
