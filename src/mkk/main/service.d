module mkk.main.service;

import mkk.common.service;
import webtank.ivy.main_service: IvyMainService;

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
IvyMainService MainService() @property
{
	IvyMainService srv = cast(IvyMainService) Service();
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

shared static this()
{
	import std.functional: toDelegate;
	Service(new IvyMainService("yarMKKMain", toDelegate(&getAuthDB)));
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