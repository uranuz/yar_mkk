module mkk_site.tools.auth_db;

import webtank.db.database: IDatabase;

private IDatabase _authDB;

IDatabase getAuthDB() @property
{
	import webtank.db.postgresql: DBPostgreSQL;
	import webtank.net.service.config: readServiceConfigFile, getServiceDatabases;

	if( _authDB is null )
	{
		auto databases = readServiceConfigFile("yarMKKMain").getServiceDatabases();
		assert( "authDB" in databases, "Ожидалась БД аутентификации в конфиге основного сервиса" );
		_authDB = new DBPostgreSQL(databases["authDB"]);
	}
	return _authDB;
}