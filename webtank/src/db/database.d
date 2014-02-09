module webtank.db.database;
///Какие-то там базовые интерфейсы по работе с базой данных
//Большой пользы пока не приносят, но как бы украшают...

import std.conv;

///Тип СУБД, или по-буржуйски Database Management System (DBMS)
enum DBMSType {PostgreSQL, MySQL, Firebird}; //Вроде как на будущее

interface IDatabase ///Интерфейс БД
{	bool connect(string connStr);  //Подключение к БД, используя строку подключения
	bool isConnected() @property;  //Вернёт true, если мы подключены к БД
	IDBQueryResult query(const(char)[] queryStr);  //Подача запроса к БД, возвращает результат
	//DBStatus getStatus() @property; //Подробнее узнать как дела у базы
	string lastErrorMessage() @property; //Прочитать последнюю ошибку
	//string getVersionInfo();
	DBMSType type() @property; //Тип системы управления БД
	
	void disconnect(); //Отключение от БД
}

interface IDBQueryResult ///Интерфейс результата запроса к БД
{	/+DBMSType type() @property; //Снова тип СУБД+/
	size_t recordCount() @property; //Число записей
	size_t fieldCount() @property;  //Число полей данных
	void clear(); //Очистить объект
	
	string getFieldName(size_t index);
	size_t getFieldIndex(string name);
	bool isNull(size_t fieldIndex, size_t recordIndex);
	string get(size_t fieldIndex, size_t recordIndex);
	string get(size_t fieldIndex, size_t recordIndex, string defaultValue);
}

///Класс исключений при работе с БД
class DBException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

///Функция создания параметризованного запроса к БД
DBQuery createQuery( IDatabase database, string expression = null )
{	return DBQuery( database, expression );
}

///Функция создания параметризованого запроса по кортежу параметров
DBQuery createQueryTuple(TL...)( IDatabase database, string expression, TL params )
	//if( is( DB : IDatabase ) )
{	return DBQuery( database, expression, params );
}

///Функция выполнения параметризованного запроса по кортежу параметров
IDBQueryResult execQueryTuple(TL...)( IDatabase database, string expression, TL params )
	//if( is( DB : IDatabase ) )
{	import webtank.db.postgresql;
	if( database.type == DBMSType.PostgreSQL )
	{	auto dbase = cast(DBPostgreSQL) database;
		if( dbase is null )
			throw new DBException("Database connection object is null!!!");
			
		return execQueryTupleImpl( dbase, expression, params );
	}
	else
		throw new DBException("execQueryTuple function for database driver " ~ database.type.to!string ~ " is not implemented!!!");
	assert(0);
}

///Параметризованный запрос к базе данных
struct DBQuery
{	import webtank.db.postgresql;
	this( IDatabase database, string expression )
	{	_dbType = database.type;
		if( _dbType == DBMSType.PostgreSQL )
		{	auto dbase = cast(DBPostgreSQL) database;
			_pgQuery = PostgreSQLQuery(dbase, expression);
		}
		else
			_notImplementedError();
	}
	
	this(TL...)( IDatabase database, string expression, TL params )
	{	this( database, expression );
		setParamTuple(params);
	}
	
	///Метод устанавливает параметры запросов по кортежу значений
	///Существующие параметры полностью перезаписываются
	ref DBQuery setParamTuple(TL...)(TL params)
	{	clearParams();
		if( _dbType == DBMSType.PostgreSQL )
			_pgQuery.setParamTuple(params);
		else
			_notImplementedError();
		return this;
	}
	
	///Устанавливает param в качестве значения параметра с номером index
	ref DBQuery setParam(T)( uint index, T param )
	{	if( _dbType == DBMSType.PostgreSQL )
			_pgQuery.setParam(index, param);
		else
			_notImplementedError();
		return this;
	}
	
	///Выполняет сформированный запрос
	IDBQueryResult exec()
	{	if( _dbType == DBMSType.PostgreSQL )
			return _pgQuery.exec();
		else
			_notImplementedError();
		assert(0);
	}
	
	///Функция задаёт выражение запроса (с местозаполнителями для параметров)
	ref DBQuery setExpr( string expression )
	{	if( _dbType == DBMSType.PostgreSQL )
			_pgQuery.setExpr(expression);
		else
			_notImplementedError();
		return this;
	}
	
	///Стирает внутренний набор параметров
	ref DBQuery clearParams()
	{	if( _dbType == DBMSType.PostgreSQL )
			_pgQuery.clearParams();
		else
			_notImplementedError();
		return this;
	}
	
	private void _notImplementedError(string file = __FILE__, size_t line = __LINE__)
	{	throw new DBException("DBQuery for database driver " ~ _dbType.to!string ~ " is not implemented!!!", file, line);
	}
	
protected:
	union {
		PostgreSQLQuery _pgQuery;
	}
	DBMSType _dbType;
}