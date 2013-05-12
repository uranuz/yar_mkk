module webtank.core.authentication;

import webtank.core.cookies;
import webtank.db.postgresql;

//Класс исключения в аутентификации
class AuthException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
		//message = msg ~ "  <" ~ file ~ ", " ~ line.to!string ~ ">";
	}
	//string message;
}

//Структура с информацией о пользователе
struct UserInfo
{	string login;
	string group;
	string name;
}

/**
	Сценарий работы с классом:
	
	
*/

///Класс "Аутентификация"
class Authentication
{	
protected:
	UserInfo _userInfo; //Информация о пользователе (не вся, только основная)
	string _sessionId;  //Ид сессии
	bool _hasUserInfo = false; //true, если получение информации о пользователе не требуется
	bool _hasSID = false; //true, если получение Ид сессии не требуется


public:
	string dbConnStr = "dbname=postgres host=localhost user=postgres password=postgres";
	
	this() //Конструктор
	{	_updateSessionId(); //При запуске пытаемся получить Ид сессии
		_updateUserInfo();  //Получаем информацию о пользователе
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	void enterUser(string login, string password)
	{	
		//Делаем запрос к БД за информацией о пользователе
		auto dbase = new DBPostgreSQL(dbConnStr);
		if ( !dbase.isConnected )
			return;
		
		auto query_res = cast(PostgreSQLQueryResult) dbase.query(
			` select id, user_group, name, password `
			` from "user" `
			` where login='`
			~ login ~ `';`
		);
		
		if( query_res.recordCount <= 0 )
			return;
		
		_userInfo.login = login;
		string user_id = ( query_res.getIsNull(0, 0) ) ? null : query_res.getValue(0, 0);
		_userInfo.group = ( query_res.getIsNull(0, 1) ) ? null : query_res.getValue(0, 1);
		_userInfo.name = ( query_res.getIsNull(0, 2) ) ? null : query_res.getValue(0, 2);
		string found_password = ( query_res.getIsNull(0, 3) ) ? null : query_res.getValue(0, 3);
		
		if( (found_password.length > 0) && (password == found_password) )
		{	//TODO: Генерировать уникальный идентификатор сессии и возвращать
			string sid = _generateSessionId(login);
			string query = 
				`insert into "session" ("id", "user_id") values ( ( '`
				~ sid ~ `' )::uuid, ` ~ user_id ~ ` );`;
			dbase.query(query);
		}
	}

	//Свойство "Информация о пользователе"
	UserInfo userInfo() @property
	{	if( _hasUserInfo )
			return _userInfo;
		else
		{	_updateUserInfo();
			return _userInfo;
		}
		assert(0); //Сюда не ходи
	}
	
	//свойство "Ид сессии"
	string sessionId() @property
	{	if( _hasSID )
			return _sessionId;
		else
		{	_updateSessionId();
			return _sessionId;
		}
		assert(0); //Сюда не ходи
	}
	
protected:
	//Служебная функция для генерации Ид сессии
	//TODO: возможно, лучше перенести в защищенную секцию, чтобы никто не мог взломать и вызвать
	string _generateSessionId(string baseStr)
	{	import std.digest.md;
		import std.datetime;
		string idSource = baseStr ~ Clock.currTime().toISOString(); //Создаём исходную строку 
		auto md5 = new MD5Digest(); 
		ubyte[] hash = md5.digest(idSource); 
		return toHexString( hash ); //Возвращаем идентификатор сессии
	}
	
	void _updateSessionId()
	{	_sessionId = null; //Сбрасываем в начале Ид сессии
		_hasSID = true; //Больше не ищем Ид сессии
	
		auto cookies = getCookies();
		string cookieSID = 
			( !cookies.hasName(`sid`) || ( cookies[`sid`].length <= 0 ) ) ? null : cookies[`sid`];
		//Прерываем, если нет Ид сессии нет в браузере
		if( cookieSID.length <= 0 ) return;
			
		//Делаем запрос к БД за информацией о сессии
		auto dbase = new DBPostgreSQL(dbConnStr);
		if ( !dbase.isConnected ) return; //Не доступа к базе

		auto query_res = cast(PostgreSQLQueryResult) dbase.query(
			//Получаем время в нужном формате (с точностью до секунд, без учёта врем. зон)
			` select to_char("expires", 'YYYY-Mon-DD HH:MM:SS') ` 
			` from session `
			` where id = '` ~ cookieSID ~ `'::uuid;`
		);
		
		if( query_res.recordCount <= 0 ) return; //Нет записей
		
		//Получаем строку со сроком годности сессии
		string expireStr = ( query_res.getIsNull(0, 0) ) ? null : query_res.getValue(0, 0);
		
		if( expireStr.length <= 0 ) return; //TODO: Подумать над этим
		import std.datetime;
		auto expiresDate = DateTime.fromSimpleString(expireStr);
		auto currentTime = cast(DateTime) Clock.currTime();
		if( currentTime <= expiresDate  ) //Проверяем срок годности
		{	_sessionId = cookieSID; }
	}
	
	void _updateUserInfo()
	{	_updateSessionId(); //Обновляем Ид сессии
		if( _sessionId.length <= 0 )
			return;
		//TODO: Добавить проверку, что у нас корректный Ид сессии
		
		//Делаем запрос к БД за информацией о пользователе
		auto dbase = new DBPostgreSQL(dbConnStr);
		if ( !dbase.isConnected )
			return;
			
		auto query_res = cast(PostgreSQLQueryResult) dbase.query(
			` select U.login, U.user_group, U.name `
			` from session `
			` join "user" as U `
			` on U.id = user_id `
			` where session.id = '` 
			~ _sessionId ~ `'::uuid;`
		);
		
		if( query_res.recordCount <= 0 )
			return;
		
		//Получаем информацию о пользователе из результата запроса
		_userInfo.login = ( query_res.getIsNull(0, 0) ) ? null : query_res.getValue(0, 0);
		_userInfo.group = ( query_res.getIsNull(0, 1) ) ? null : query_res.getValue(0, 1);
		_userInfo.name = ( query_res.getIsNull(0, 2) ) ? null : query_res.getValue(0, 2);
	}
}






