module mkk.tools.auth_db;

import webtank.db: IDatabase;

private IDatabase _authDB;
private IDatabase _commonDB;

string getDBConnString(string service, string dbIdent)
{
	import webtank.net.service.config: readServiceConfigFile, getServiceDatabases;
	import std.exception: enforce;

	auto databases = readServiceConfigFile(service).getServiceDatabases();
	auto dbConnStr = databases.get(dbIdent, null);
	enforce(
		dbConnStr.length > 0,
		`Не удалось получить строку подключения к базе данных "` ~ dbIdent ~ `" для сервиса "` ~ service ~ `"!`
	);
	return dbConnStr;
}

import webtank.db.postgresql: DBPostgreSQL;

IDatabase getAuthDB() @property
{
	if( _authDB is null ) {
		_authDB = new DBPostgreSQL(getDBConnString("yarMKKMain", "authDB"));
	}
	return _authDB;
}

IDatabase getCommonDB() @property
{
	if( _commonDB is null ) {
		_commonDB = new DBPostgreSQL(getDBConnString("yarMKKMain", "commonDB"));
	}
	return _commonDB;
}