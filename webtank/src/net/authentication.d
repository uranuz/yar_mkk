module webtank.net.authentication;

import std.conv;

import webtank.net.cookies;
import webtank.db.postgresql;


///В разработке: Политика аутентификации
class AuthPolicy
{	//Два режима: разрешать (allow) или запрещать (deny)
	enum Mode {allow, deny};
	Mode mode;
	/**
		Три вида пользователей или групп:
		1. Обычные пользователи или группы:
			Этим пользователям разрешается доступ, если mode = Mode.allow и запрещается
			если mode = Mode.deny
		2. Особые пользователи (привелигированные) или группы:
			Для этих пользователей обратная ситуация. Если mode = Mode.allow, то доступ
			запрещается и, если mode = Mode.deny, то разрешается
		3. 
	*/
}

//Класс исключения в аутентификации
class AuthException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
		//message = msg ~ "  <" ~ file ~ ", " ~ line.to!string ~ ">";
	}
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

enum string dbLibLogFile = `/home/test_serv/sites/test/logs/webtank.log`;

///Класс "Аутентификация"
class Authentication
{	
protected:
	UserInfo _userInfo; //Информация о пользователе (не вся, только основная)
	SessionIdType _sessionId;  //Ид сессии
	bool _hasUserInfo = false; //true, если получение информации о пользователе не требуется
	bool _hasSID = false; //true, если получение Ид сессии не требуется
	immutable(size_t) _sessionLifetime = 15; //Время жизни сессии в минутах

public:
	enum SessionIdSize = 16;
	alias ubyte[SessionIdSize] SessionIdType;
	
	string dbConnStr = "dbname=postgres host=localhost user=postgres password=postgres";
	
	this() //Конструктор
	{	_updateSessionId(); //При запуске пытаемся получить Ид сессии
		_updateUserInfo();  //Получаем информацию о пользователе
	}
	
	//Функция возвращает true, если вход пользователя выполнен и false иначе
	bool isLoggedIn() @property
	{	return ( sessionId != SessionIdType.init ); //TODO: Улучшить проверку
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	SessionIdType enterUser(string login, string password)
	{	
		//Делаем запрос к БД за информацией о пользователе
		auto dbase = new DBPostgreSQL(dbConnStr);
		if ( !dbase.isConnected )
			return SessionIdType.init;
		
		auto query_res = cast(PostgreSQLQueryResult) dbase.query(
			` select id, password `
			` from "user" `
			` where login='`
			~ pgEscapeStr( login ) ~ `';`
		);
		
		if( query_res.recordCount <= 0 )
			return SessionIdType.init;
			
		string user_id = query_res.getValue(0, 0, null);
		string found_password = query_res.getValue(0, 1, null);
		
		try { //Логирование запросов к БД для отладки
			import std.file;
			std.file.append( dbLibLogFile, 
				"--------------------\r\n"
				"Authentication.enterUser()\r\n"
				"user_id: " ~ user_id 
				~ ";  found_password: " ~ found_password ~ "\r\n"
			);
		} catch(Exception) {}
		
		//Проверка пароля
		if( (found_password.length > 0) && (password.length > 0) && (password == found_password) ) 
		{	//TODO: Генерировать уникальный идентификатор сессии и возвращать
			import std.digest.digest;
			SessionIdType sid = _generateSessionId(login);
			try { //Логирование запросов к БД для отладки
				import std.file;
				std.file.append( dbLibLogFile, 
					"sid: " ~ toHexString(sid) ~ "\r\n"
				);
			} catch(Exception) {}
			
			string sidStr = std.digest.digest.toHexString(sid);
			string query = 
				` insert into "session" ("id", "user_id", "expires") values ( ( '`
				~ sidStr ~ `' )::uuid, ` ~ pgEscapeStr( user_id  )
				~ `, ( current_timestamp + interval '` 
				~ pgEscapeStr( _sessionLifetime.to!string ) ~ ` minutes' )  )`
				~ ` returning 'authenticated';`;
			auto newSIDStatusRes = cast(PostgreSQLQueryResult) dbase.query(query);
			if( newSIDStatusRes.recordCount <= 0 )
				return SessionIdType.init;
			string statusStr = newSIDStatusRes.getValue(0, 0, "");
			if( statusStr == "authenticated" )
			{	_sessionId = sid;
				_hasUserInfo = false;
				return sid;  //Аутентификация завершена успешно
			}
			else 
				return SessionIdType.init;
		}
		return SessionIdType.init;
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
	
	
	//TODO: Привести sessionId к ubyte[16]
	//свойство "Ид сессии"
	SessionIdType sessionId() @property
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
	SessionIdType _generateSessionId(string baseStr)
	{	import std.digest.md;
		import std.datetime;
		string idSource = baseStr ~ Clock.currTime().toISOString(); //Создаём исходную строку 
		return md5Of(idSource); //Возвращаем идентификатор сессии
	}
	
	//Служебная функция обновления Ид сессии
	void _updateSessionId()
	{	_sessionId = SessionIdType.init; //Сбрасываем в начале Ид сессии
		auto cookies = getCookies();
		string cookieSIDStr = ( !cookies.hasName(`sid`) ) ? null : cookies[`sid`];
		//Прерываем, если нет Ид сессии нет в браузере
		if( cookieSIDStr.length <= 0 ) return;
		
		import std.digest.digest;
		import webtank.common.conv;
		auto cookieSID = hexStringToByteArray(cookieSIDStr);
		if( cookieSID == SessionIdType.init )
			return;
		cookieSIDStr = toHexString( cookieSID );
		
		_hasSID = false; //Если будет сбой работы с БД, то будем искать снова
		//Делаем запрос к БД за информацией о сессии
		auto dbase = new DBPostgreSQL(dbConnStr);
		if ( !dbase.isConnected ) return; //Не доступа к базе

		auto query_res = cast(PostgreSQLQueryResult) dbase.query(
			//Получим 1, если срок действия не истек или ничего
			`select 1 from session 
			where id = '` ~ cookieSIDStr ~ `'::uuid and current_timestamp < "expires";`
		);
		
		//К БД подключились
		_hasSID = true; //Больше не ищем Ид сессии
		if( query_res.recordCount > 0 )
			_sessionId = cookieSID; 
		else
			return; //Нет записей
	}
	
	//Служебная функция обновления информации о пользователе
	void _updateUserInfo()
	{	_hasUserInfo = false;
		_updateSessionId(); //Обновляем Ид сессии
		if( _sessionId == SessionIdType.init )
			return;
		//TODO: Добавить проверку, что у нас корректный Ид сессии
		
		//Делаем запрос к БД за информацией о пользователе
		auto dbase = new DBPostgreSQL(dbConnStr);
		if ( !dbase.isConnected )
			return;
			
		import std.digest.digest;
		string sessionIdStr = toHexString( _sessionId );
		auto query_res = cast(PostgreSQLQueryResult) dbase.query(
			` select U.login, U.user_group, U.name `
			` from session `
			` join "user" as U `
			` on U.id = user_id `
			` where session.id = '` 
			~ sessionIdStr ~ `'::uuid;`
		);
		
		if( query_res.recordCount <= 0 )
			return;
		
		//Получаем информацию о пользователе из результата запроса
		_userInfo.login = query_res.getValue(0, 0, null);
		_userInfo.group = query_res.getValue(0, 1, null);
		_userInfo.name = query_res.getValue(0, 2, null);
		_hasUserInfo = true;
	}
}






