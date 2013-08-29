module webtank.net.authentication;

import std.conv;

import webtank.net.http_cookie, webtank.db.postgresql;

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

///Класс "Аутентификация"
class Authentication
{	
protected:
	UserInfo _userInfo = anonymousUI; //Информация о пользователе (не вся, только основная)
	SessionIdType _sessionId;  //Ид сессии
	bool _hasUserInfo = false; //true, если получение информации о пользователе не требуется
	bool _hasSID = false; //true, если получение Ид сессии не требуется
	immutable(size_t) _sessionLifetime = 15; //Время жизни сессии в минутах
	string _authDBConnStr;
	string _errorLogFile;

public:
	enum uint sessionIdSize = 16;
	enum uint SIDStrMinSize = 2 * sessionIdSize; //Минимальная длина строкового представления Ид сессии
	enum uint loginMinLength = 3;  //Минимальная длина логина
	enum uint passwordMinLength = 6;  //Минимальная длина пароля
	alias ubyte[sessionIdSize] SessionIdType;
	
	enum UserInfo anonymousUI = UserInfo("anonymous", "anonymous", "anonymous");

	
	this(string dbConnStr, string errorLogFile) //Конструктор
	{	_authDBConnStr = DBConnStr;
		_errorLogFile = errorLogFile;
	}
	
	//Функция возвращает true, если вход пользователя выполнен и false иначе
	bool isLoggedIn() @property
	{	return ( sessionId != SessionIdType.init ); //TODO: Улучшить проверку
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	void enterUser(string login, string password)
	{	auto dbase = new DBPostgreSQL(_authDBConnStr);
		if( (dbase is null) || !dbase.isConnected )
			return;
			
		if( login.length < loginMinLength ) //Проверяем длину логина
			return;
		
		//Делаем запрос к БД за информацией о пользователе
		auto query_res = dbase.query(
			` select id, password `
			` from "user" `
			` where login='`
			~ pgEscapeStr( login ) ~ `';`
		);
		
		if( ( query_res.recordCount == 1 ) && ( query_res.fieldCount == 1 ) )
			return;
			
		string user_id = query_res.get(0, 0, null);
		string found_password = query_res.get(1, 0, null);
		
		try { //Логирование запросов к БД для отладки
			import std.file;
			std.file.append( _errorLogFile, 
				"--------------------\r\n"
				"Authentication.enterUser()\r\n"
				"user_id: " ~ user_id 
				~ ";  found_password: " ~ found_password ~ "\r\n"
			);
		} catch(Exception) {}
		
		//Проверка пароля
		if( (found_password.length >= passwordMinLength ) && 
			(password.length >= passwordMinLength ) && 
			(password == found_password) ) 
		{	//TODO: Генерировать уникальный идентификатор сессии и возвращать
			import std.digest.digest;
			SessionIdType sid = generateSessionId(login);
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
			auto newSIDStatusRes = dbase.query(query);
			if( newSIDStatusRes.recordCount <= 0 )
				return SessionIdType.init;
			string statusStr = newSIDStatusRes.get(0, 0, "");
			if( statusStr == "authenticated" )
			{	_sessionId = sid;
				_hasUserInfo = false;
				return sid;  //Аутентификация завершена успешно
			}
		}
		return SessionIdType.init;
	}

	//Свойство "Информация о пользователе"
	UserInfo userInfo() @property
	{	if( !_hasUserInfo )
		{	_userInfo = getUserInfo( sessionId, new DBPostgreSQL(_authDBConnStr) );
			_hasUserInfo = true;
		}
		return _userInfo;
	}
	
	//свойство "Ид сессии"
	SessionIdType sessionId() @property
	{	if( !_hasSID )
		{	
			_sessionId = verifySessionId( SIDString, new DBPostgreSQL(_authDBConnStr) );
			_userInfo = anonymousUI;
			_hasUserInfo = false; //Раз получили Ид сессии на всякий случай ставим флаг
			_hasSID = true;
		}
		return _sessionId;
	}
}

//Служебная функция для генерации Ид сессии
SessionIdType generateSessionId(string baseStr)
{	import std.digest.md;
	import std.datetime;
	string idSource = baseStr ~ Clock.currTime().toISOString(); //Создаём исходную строку 
	return md5Of(idSource); //Возвращаем идентификатор сессии
}

//Служебная проверки и получения идентификатора сессии
SessionIdType verifySessionId(string SIDString, DBPostgreSQL dbase)
{	
	if( (dbase is null) || !dbase.isConnected )
		return SessionIdType.init; //Не доступа к базе
		
	//Прерываем, если нет Ид сессии нет в браузере
	if( SIDString.length <= SIDStrMinSize ) 
		return SessionIdType.init;
	
	import std.digest.digest;
	import webtank.common.conv;
	auto sessionId = hexStringToByteArray(SIDString);
	if( sessionId == SessionIdType.init )
		return SessionIdType.init;
	SIDString = toHexString( sessionId );  //Важно
	
	//Делаем запрос к БД за информацией о сессии
	auto query_res = dbase.query(
		//Получим 1, если срок действия не истек или ничего
		`select 1 from session 
		where id = '` ~ SIDString ~ `'::uuid and current_timestamp < "expires";`
	);
	
	//К БД подключились
	if( ( query_res.recordCount == 1 ) && ( query_res.fieldCount == 1 ) )
		return sessionId; 
	else
		return SessionIdType.init; //Нет записей
}

//Служебная функция получения информации о пользователе
UserInfo getUserInfo( 
	SessionIdType sessionId, 
	DBPostgreSQL dbase,
	UserInfo anonymousUI = Authentication.anonymousUI ) 
)
{	if( (dbase is null) || !dbase.isConnected )
		return anonymousUI;
	
	if( sessionId == SessionIdType.init )
		return anonymousUI; //Не доступа к базе
	//TODO: Добавить проверку, что у нас корректный Ид сессии
	
	//Делаем запрос к БД за информацией о пользователе
	import std.digest.digest;
	auto query_res = dbase.query(
		` select U.login, U.user_group, U.name `
		` from session `
		` join "user" as U `
		` on U.id = user_id `
		` where session.id = '` 
		~ std.digest.digest.toHexString( sessionId ) ~ `'::uuid;`
	);
	
	if( (query_res.recordCount != 1) && (query_res.fieldCount != 3) )
		return anonymousUI;
	
	//Получаем информацию о пользователе из результата запроса
	return UserInfo(
		query_res.get(0, 0, null), //login
		query_res.get(1, 0, null), //user_group
		query_res.get(2, 0, null)  //name
	);
}




