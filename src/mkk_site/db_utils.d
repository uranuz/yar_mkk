module mkk_site.db_utils;

import webtank.db.database, webtank.db.postgresql;

import mkk_site.utils;
import mkk_site.site_data_old;

IDatabase _commonDatabase;
IDatabase _authDatabase;

static this()
{
	//Создаем объекты подключений при старте нити исполнения
	_commonDatabase = new DBPostgreSQL(commonDBConnStr);
	_authDatabase = new DBPostgreSQL(authDBConnStr);
}

IDatabase getCommonDB()
{
	if( !_commonDatabase.isConnected )
	{
		_commonDatabase.destroy();
		_commonDatabase = new DBPostgreSQL(commonDBConnStr);
	}
	return _commonDatabase;
}

IDatabase getAuthDB()
{
	if( !_authDatabase.isConnected )
	{
		_authDatabase.destroy();
		_authDatabase = new DBPostgreSQL(authDBConnStr);
	}
	return _authDatabase;
}