module mkk_site.main_service.db_manager;

public import webtank.db.database;

// Класс для управления соединениями с базой для основного сервиса МКК
class MKKMainDatabaseManager
{
	import webtank.db.postgresql;

private:
	string _commonDBConnStr;
	string _authDBConnStr;

	IDatabase _commonDB;
	IDatabase _authDB;

public:
	this(string[string] connStrings)
	{
		assert( "commonDB" in connStrings, "Expected connection string for common MKK database!" );
		assert( "authDB" in connStrings, "Expected connection string for common MKK database!" );

		_commonDBConnStr = connStrings["commonDB"];
		_authDBConnStr = connStrings["authDB"];
	}

	private static IDatabase _checkDBConnection(ref IDatabase dbConn, string connStr)
	{
		if( !dbConn || !dbConn.isConnected )
		{
			if( dbConn ) {
				dbConn.destroy();
			}
			
			dbConn = new DBPostgreSQL(connStr);
		}
		return dbConn;
	}

	// Возвращает объект подключения к основной базе МКК
	IDatabase commonDB() @property {
		return _checkDBConnection(_commonDB, _commonDBConnStr);
	}

	// Возвращает объект подключения к служебной базе МКК (базе аутентификации)
	IDatabase authDB() @property {
		return _checkDBConnection(_authDB, _authDBConnStr);
	}
}