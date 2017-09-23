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

	DBLogerMethod _dbLogerMethod;

public:
	this(string[string] connStrings, DBLogerMethod dbLogerMethod = null)
	{
		assert( "commonDB" in connStrings, "Expected connection string for common MKK database!" );
		assert( "authDB" in connStrings, "Expected connection string for auth MKK database!" );

		_commonDBConnStr = connStrings["commonDB"];
		_authDBConnStr = connStrings["authDB"];
		_dbLogerMethod = dbLogerMethod;
	}

	private static IDatabase _checkDBConnection(ref IDatabase dbConn, string connStr, DBLogerMethod dbLogerMethod)
	{
		if( !dbConn || !dbConn.isConnected )
		{
			if( dbConn ) {
				dbConn.destroy();
			}

			dbConn = new DBPostgreSQL(connStr, dbLogerMethod);
		}
		return dbConn;
	}

	// Возвращает объект подключения к основной базе МКК
	IDatabase commonDB() @property {
		return _checkDBConnection(_commonDB, _commonDBConnStr, _dbLogerMethod);
	}

	// Возвращает объект подключения к служебной базе МКК (базе аутентификации)
	IDatabase authDB() @property {
		return _checkDBConnection(_authDB, _authDBConnStr, _dbLogerMethod);
	}
}