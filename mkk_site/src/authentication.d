module mkk_site.authentication;

import std.conv;

import webtank.db.postgresql;

//Класс исключения в аутентификации
class AuthException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
		//message = msg ~ "  <" ~ file ~ ", " ~ line.to!string ~ ">";
	}
}

enum uint sessionIdSize = 16;
enum uint SIDStrMinSize = 2 * sessionIdSize; //Минимальная длина строкового представления Ид сессии
enum uint loginMinLength = 3;  //Минимальная длина логина
enum uint passwordMinLength = 6;  //Минимальная длина пароля
alias ubyte[sessionIdSize] SessionIdType;

//Структура с информацией о пользователе
struct UserInfo
{	string login;
	string group;
	string name;
}

///Класс "Аутентификация"
class Authentication
{	
protected:
	UserInfo _userInfo = anonymousUI; //Информация о пользователе (не вся, только основная)
	SessionIdType _sessionId;  //Ид сессии
	bool _updateSID = true;
	bool _updateUserInfo = true;
	string _SIDString;
	immutable(size_t) _sessionLifetime = 15; //Время жизни сессии в минутах
	string _authDBConnStr;
	string _errorLogFile;

public:
	enum UserInfo anonymousUI = UserInfo("anonymous", "anonymous", "anonymous");

	this(string SIDString, string dbConnStr, string errorLogFile) //Конструктор
	{	_authDBConnStr = dbConnStr;
		_errorLogFile = errorLogFile;
		_SIDString = SIDString;
		identify(_SIDString);
	}
	
	this(string SIDString, string dbConnStr) //Конструктор
	{	_authDBConnStr = dbConnStr;
		_SIDString = SIDString;	
		identify(_SIDString);
	}
	
	void identify(string SIDString)
	{	if( SIDString.length >= SIDStrMinSize )
		{	auto db = new DBPostgreSQL(_authDBConnStr);
			_sessionId = verifySessionId( SIDString, db );
			if( _sessionId != SessionIdType.init )
				_userInfo = getUserInfo( _sessionId, db, anonymousUI );
		}
	}
	
	//Функция возвращает true, если вход пользователя выполнен и false иначе
	bool isIdentified() @property
	{	return ( ( _sessionId != SessionIdType.init ) /+&& ( _userInfo != anonymousUI )+/  ); //TODO: Улучшить проверку
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	void authenticate(string login, string password)
	{	try { //Логирование запросов к БД для отладки
			import std.file;
			std.file.append( _errorLogFile, 
				"--------------------\r\n"
				"Authentication.authenticate: _authDBConnStr = \r\n"
				~ _authDBConnStr ~ "\r\n"
			);
		} catch(Exception) {}
	
		auto dbase = new DBPostgreSQL(_authDBConnStr);
		if( (dbase is null) || (!dbase.isConnected) )
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
				std.file.append( _errorLogFile, 
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
				return;
			string statusStr = newSIDStatusRes.get(0, 0, "");
			if( statusStr == "authenticated" )
			{	_sessionId = sid;
				_updateSID = false;
				_updateUserInfo = true;
				//Аутентификация завершена успешно
			}
		}
	}

	//Свойство "Информация о пользователе"
	UserInfo userInfo() @property
	{	if( _updateUserInfo )
		{	_userInfo = getUserInfo( _sessionId, new DBPostgreSQL(_authDBConnStr) );
			_updateUserInfo = false;
		}
		return _userInfo;
	}
	
	//свойство "Ид сессии"
	SessionIdType sessionId() @property
	{	if( _updateSID )
		{	_sessionId = verifySessionId( _SIDString, new DBPostgreSQL(_authDBConnStr) );
			_userInfo = anonymousUI;
			_updateUserInfo = true; //Раз получили Ид сессии на всякий случай ставим флаг
			_updateSID = false;
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
	if( SIDString.length < SIDStrMinSize ) 
		return SessionIdType.init;
	
	import webtank.common.conv;
	auto SID = hexStringToStaticByteArray!(sessionIdSize)(SIDString);
	if( SID == SessionIdType.init )
		return SessionIdType.init;
	SIDString = webtank.common.conv.toHexString( SID );  //Важно
	
	//Делаем запрос к БД за информацией о сессии
	auto query_res = dbase.query(
		//Получим 1, если срок действия не истек или ничего
		`select 1 from session 
		where id = '` ~ SIDString ~ `'::uuid and current_timestamp < "expires";`
	);
	
	//К БД подключились
	if( ( query_res.recordCount == 1 ) && ( query_res.fieldCount == 1 ) )
		return SID; 
	else
		return SessionIdType.init; //Нет записей
}

//Служебная функция получения информации о пользователе
UserInfo getUserInfo( 
	SessionIdType sessionId, 
	DBPostgreSQL dbase,
	UserInfo anonymousUI = Authentication.anonymousUI
)
{	if( (dbase is null) || !dbase.isConnected )
		return anonymousUI;
	
	if( sessionId == SessionIdType.init )
		return anonymousUI; //Не доступа к базе
	//TODO: Добавить проверку, что у нас корректный Ид сессии
	
	//Делаем запрос к БД за информацией о пользователе
	import webtank.common.conv;
	auto query_res = dbase.query(
		` select U.login, U.user_group, U.name `
		` from session `
		` join "user" as U `
		` on U.id = user_id `
		` where session.id = '` 
		~ webtank.common.conv.toHexString( sessionId ) ~ `'::uuid;`
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
