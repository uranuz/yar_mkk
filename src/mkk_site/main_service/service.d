module mkk_site.main_service.service;

import webtank.net.service.json_rpc_service: JSON_RPCService;
import mkk_site.common.service;

class MKKMainService: JSON_RPCService
{
	import mkk_site.security.core.access_control: MKKMainAccessController;
	import std.functional: toDelegate;

	this(string serviceName)
	{
		super(serviceName,
			new MKKMainAccessController(toDelegate(&getAuthDB))
		);
	}

	override MKKMainAccessController accessController() @property
	{
		auto controller = cast(MKKMainAccessController) _accessController;
		assert(controller, `MKK access controller is null`);
		return controller;
	}
}

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
MKKMainService MainService() @property
{
	MKKMainService srv = cast(MKKMainService) Service();
	assert( srv, `View service is null` );
	return srv;
}

// Метод для получения экземпляра объекта подключения к основной БД сервиса МКК
IDatabase getCommonDB() @property
{
	assert( _commonDB, `MKK main service common DB connection is not initialized!` );
	return _commonDB;
}

// Метод для получения экземпляра объекта подключения к БД аутентификации сервиса МКК
IDatabase getAuthDB() @property
{
	assert( _authDB, `MKK main service auth DB connection is not initialized!` );
	return _authDB;
}

shared static this() {
	Service(new MKKMainService("yarMKKMain"));
}

import webtank.db.database: IDatabase;

// Each thread uses it's own thread local instance of connection to database,
// because PostgreSQL connection is not thread safe
private IDatabase _commonDB;
private IDatabase _authDB;

static this()
{
	import webtank.net.service.config: getServiceDatabases;
	import webtank.db.postgresql: DBPostgreSQL;

	_commonDB = new DBPostgreSQL(MainService.dbConnStrings["commonDB"], &MainService.databaseLogerMethod);
	_authDB = new DBPostgreSQL(MainService.dbConnStrings["authDB"], &MainService.databaseLogerMethod);
}