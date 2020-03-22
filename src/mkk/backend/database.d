module mkk.backend.database;

import webtank.db.iface.factory: IDatabaseFactory;
import webtank.db.iface.database: IDatabase;
import webtank.db.consts: DBRole;

import mkk.common.service: Service;

// Получить фабрику баз данных по текущему сервису
IDatabaseFactory _getDBFactory()
{
	import std.exception: enforce;
	IDatabaseFactory fact = cast(IDatabaseFactory) Service();
	enforce(fact !is null, `Service is needed to be also an instance of IDatabaseFactory!`);
	return fact;
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
	return _getDBFactory().getDB(DBID.common);
}

// Метод для получения экземпляра объекта подключения к БД аутентификации сервиса МКК
IDatabase getAuthDB() @property {
	return _getDBFactory().getDB(DBID.auth);
}