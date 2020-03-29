module mkk.backend.database;

import webtank.db.iface.factory: IDatabaseFactory;
import webtank.db.iface.database: IDatabase;
import webtank.db.consts: DBRole;

version(mkk_script)
{
	private __gshared IDatabaseFactory _mkk_script_db_factory;

	shared static this()
	{
		import webtank.net.service.config: readServiceConfigFile, getServiceDatabases;
		import webtank.db.per_thread_pool: DBPerThreadPool;
		import webtank.db.factory: DBFactory;

		// Спец. конфигурация сервиса имеет настройки подключения ко всем базам
		auto databases = readServiceConfigFile(`yarMKKScript`).getServiceDatabases();
		_mkk_script_db_factory = new DBPerThreadPool(new DBFactory(databases));
	}
}

// Получить фабрику баз данных по текущему сервису
IDatabaseFactory DBFactory() @property
{
	version(mkk_script) {
		return _mkk_script_db_factory; // Фабрика баз для исполнения скриптов без создания сервиса
	}
	else
	{
		import mkk.common.service: Service;
		import std.exception: enforce;

		IDatabaseFactory fact = cast(IDatabaseFactory) Service();
		enforce(fact !is null, `Service is needed to be also an instance of IDatabaseFactory!`);
		return fact;
	}
}

// Идентификаторы баз в конфигурации сервиса
enum DBID: string
{
	common = `commonDB`,
	auth = DBRole.auth,
	history = DBRole.history
}

// Метод для получения экземпляра объекта подключения к основной БД сервиса МКК
IDatabase getCommonDB() @property {
	return DBFactory().getDB(DBID.common);
}

// Метод для получения экземпляра объекта подключения к БД аутентификации сервиса МКК
IDatabase getAuthDB() @property {
	return DBFactory().getDB(DBID.auth);
}

// Метод для получения экземпляра объекта подключения к БД аутентификации сервиса МКК
IDatabase getHistoryDB() @property {
	return DBFactory().getDB(DBID.history);
}