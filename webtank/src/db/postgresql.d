module webtank.db.postgresql;

pragma(lib, "pq");

import std.string, std.exception, std.conv, std.stdio;

import webtank.db.database;

extern (C)
{
	struct PGconn;
	struct PGresult;
	
	PGconn *PQconnectdb(const char *conninfo);  //New connection to the database server.
	PGresult *PQexec(PGconn *conn, //Submits a command to the server 
	                 const char *command); //and waits for the result.
	                 
	void PQfinish(PGconn *conn); //Closes the connection to the server. Also frees 
	       //memory used by the PGconn object.
	
	int PQntuples(const PGresult *res); //Number of rows in table
	int PQnfields(const PGresult *res); //Number of columns in table
	char *PQfname(const PGresult *res, int column_number); //Returns name of column 
	//with specified number or NULL if number is out of range
	
	int PQfnumber(const PGresult *res, //Returns column number with specified or -1 if
	          const char *column_name); //the given name does not match any column
	
	char *PQgetvalue(const PGresult *res, //Returns a single field value of one
	                 int row_number,      //row of a PGresult. Row and column 
                    int column_number);  //numbers start at 0
                    
	int PQgetisnull(const PGresult *res, //Tests a field for a null value. 
                   int row_number,      //Row and column numbers start at 0.
                   int column_number);
                   
	int PQgetlength(const PGresult *res, //Returns the actual length of a field 
                int row_number,         //value in bytes. Row and column numbers 
                int column_number);     //start at 0.
                
	void PQclear(PGresult *res); //Frees the storage associated with a PGresult.           
	
	char *PQerrorMessage(const PGconn *conn); //Returns the error message most 
	//recently generated by an operation on the connection.
	

	enum int CONNECTION_OK=0;
	//enum int CONNECTION_BAD=1,
	
	
	//Returns the status of the connection.
	int PQstatus(const PGconn *conn);
}

enum string dbQueryLogFile = `/home/test_serv/sites/test/logs/db_query.log`;

///Класс работы с СУБД PostgreSQL
class DBPostgreSQL : IDatabase
{
protected:
	PGconn *_conn;
	
public:
	//Конструктор объекта, принимает строку подключения как параметр
	this( string connStr ) //Конструктор объекта, принимает строку подключения
	{	/*if (connStr !is null)*/ connect(connStr);
	}
	
	//Конструктор "ничегонеделанья"
	this() {}
	
	override {
		//Ф-ция подключения к БД
		bool connect(string connStr)
		{	_conn=PQconnectdb(toStringz(connStr));
			if (_conn is null) return false; //TODO: Сделать что-нибудь
			else return true; 
		}
		
		//Проверить, что подключены
		bool isConnected() @property
		{	return (PQstatus(_conn)==CONNECTION_OK);
		}
		
		//Запрос к БД, строка запроса в качестве параметра
		//Возвращает объект унаследованный от интерфейса результата запроса
		IDBQueryResult query(string sql)
		{	try { //Логирование запросов к БД для отладки
				import std.file;
				std.file.append( dbQueryLogFile, 
					"--------------------\r\n"
					~ sql ~ "\r\n"
				);
			} catch(Exception)
			{}
			
			PGresult* Res=PQexec(_conn, toStringz(sql));
			//if (Res is null) return null;
			//else 
			return new PostgreSQLQueryResult(this, Res);
			//else ; //TODO: Add error there or doing nothing
		}
		
		//Получение строки с недавней ошибкой
		string getLastError()
		{	return PQerrorMessage(_conn).to!string; }
		
		//Тип СУБД
		DBMSType type() @property
		{	return DBMSType.postgreSQL; }
		
		//Отключиться от БД
		void disconnect()
		{	if( _conn !is null )
			{	PQfinish(_conn); 
				_conn = null;
			}
		}
	}
	
	~this() //Деструктор объекта
	{	if (_conn !is null) 
		{	PQfinish(_conn);
			_conn = null;
		}
	}
	
	
	//TODO: Этот метод дублирует метод getLastError
	string errorMessage()
	{	if( _conn !is null )
			return to!string(PQerrorMessage(_conn));
		else return null;
	}
	
}

///Результат запроса для СУБД PostgreSQL
class PostgreSQLQueryResult: IDBQueryResult
{	
protected:
	PGresult *_queryResult;
	DBPostgreSQL _database;
	
public:
	this( DBPostgreSQL db, PGresult* result )
	{	_queryResult = result;
		_database = db;
	}
	
	///ПЕРЕОПРЕДЕЛЕНИЕ ИНТЕРФЕЙСНЫХ ФУНКЦИЙ
	override {
		//Получение типа СУБД
// 		DBMSType type() @property
// 		{	return _database.type; }
		
		
		//Количество записей
		size_t recordCount()
		{	if( _queryResult )
				return ( PQntuples(_queryResult) ).to!size_t;
			else return 0;
		}
		
		//Количество полей данных (столбцов)
		size_t fieldCount()
		{	if( _queryResult )
				return ( PQnfields(_queryResult) ).to!size_t;
			else return 0;
		}
		
		//Очистить результат запроса
		void clear()
		{	if( _queryResult !is null )
			{	PQclear(_queryResult); 
				_queryResult = null;
			}
		}
		
		
		//Получение имени поля по индексу
		string getFieldName(size_t index) 
		{	if( _queryResult )
				return ( PQfname( _queryResult, index.to!int ) ).to!string;
			else return null;
		}
		
		//Получение индекса поля по имени
		size_t getFieldIndex(string name)
		{	if( _queryResult )
				return ( PQfnumber(_queryResult, toStringz(name) ) ).to!size_t;
			else return -1;
		}
		
		//Вернёт true, если поле пустое, и false иначе
		bool getIsNull(size_t recordIndex, size_t fieldIndex)
		{	if( _queryResult )
				return ( PQgetisnull(_queryResult, recordIndex.to!int, fieldIndex.to!int ) == 1 ) ? true : false;
			assert(0);
		}
		
		//Получение значения ячейки данных в виде строки
		//Неопределённое поведение, если ячейка пуста или её нет
		string getValue(size_t recordIndex, size_t fieldIndex)
		{	if( _queryResult )
				return ( PQgetvalue(_queryResult, recordIndex.to!int, fieldIndex.to!int ) ).to!string;
			else return null;
		}
		
		//Получение значения ячейки данных в виде строки
		//Если ячейка пуста то вернёт значение параметра defaultValue
		string getValue(size_t recordIndex, size_t fieldIndex, string defaultValue)
		{	if( getIsNull(recordIndex, fieldIndex) ) 
				return defaultValue;
			else
				return getValue(recordIndex, fieldIndex);
		}
	}

	~this() //Освобождаем результат запроса
	{	if( _queryResult !is null )
		{	PQclear(_queryResult); 
			_queryResult = null;
		}
	}
}

//Функция возвращает переданную строку, но с удвоенными кавычками
string pgEscapeStr(string str)
{	string result;
	foreach(s; str)
	{	if( s == '\'' ) result ~= "\'\'";
		else result ~= s;
	}
	return result;
}