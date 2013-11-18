module mkk_site.authentication;

import std.conv;

import webtank.db.postgresql, webtank.net.utils, webtank.net.access_control, webtank.net.connection, webtank.net.http.context, webtank.common.conv;;

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

enum SIDCookieName = "__sid__";

class MKK_SiteUser: IUser
{
	this( string login, string group, string name, string email )
	{	_login = login;
		_group = group;
		_name = name;
		_email = email;
	}
	
	override {
		///Строка для идентификации пользователя
		string login() @property
		{	return _login; }
		
		///Функция возвращает true, если пользователь входит в группу
		bool isInGroup(string groupName)
		{	return ( groupName == _group ); }
		
		///Публикуемое имя пользователя
		string name() @property
		{	return _name; }
		
		///Адрес эл. почты пользователя для рассылки служебной информации от сервера
		string email() @property
		{	return _email; }
	}
	
protected:
	string _login;
	string _group;
	string _name;
	string _email;
}

class MKK_SiteAccessTicket: IAccessTicket
{	
	this( IUser user, SessionIdType sessionId )
	{	_user = user; 
		_sessionId = sessionId;
	}
	
	///Пользователь-владелец карты
	override IUser user() @property
	{	return _user; }
	
	///Возвращает true, если владелец успешно прошёл проверку подлинности. Иначе false
	override bool isAuthenticated() @property
	{	return ( ( _sessionId != SessionIdType.init ) /+&& ( _userInfo != anonymousUI )+/  ); //TODO: Улучшить проверку
	}
	
// 	//свойство "Ид сессии"
// 	SessionIdType sessionId() @property
// 	{	if( _updateSID )
// 		{	_sessionId = verifySessionId( _SIDString, new DBPostgreSQL(_authDBConnStr) );
// 			_userInfo = anonymousUI;
// 			_updateUserInfo = true; //Раз получили Ид сессии на всякий случай ставим флаг
// 			_updateSID = false;
// 		}
// 		return _sessionId;
// 	}
	
protected:
	SessionIdType _sessionId;  //Ид сессии
	IUser _user;
}

///Класс управляет выдачей билетов для доступа
class MKK_SiteAccessTicketManager: IAccessTicketManager
{	
protected:
	immutable(size_t) _sessionLifetime = 15; //Время жизни сессии в минутах
	string _authDBConnStr;
	string _errorLogFile;

public:
	this(string dbConnStr, string errorLogFile) //Конструктор
	{	_authDBConnStr = dbConnStr;
		_errorLogFile = errorLogFile;
	}
	
	this(string dbConnStr) //Конструктор
	{	_authDBConnStr = dbConnStr;
	}
	
	override IAccessTicket getTicket(IConnectionContext context)
	{
		auto ctx = cast(HTTPContext) context;
		
		if( ctx is null || ctx.request is null || ctx.request.cookie is null  )
			return null;
		
		string SIDString = ctx.request.cookie.get( SIDCookieName, null );
		
		string login;
		string group;
		string name;
		string email;
		
		SessionIdType sessionId;
		
		MKK_SiteAccessTicket createTicket()
		{	auto user = new MKK_SiteUser(
				login, //login
				group, //group
				name,  //name
				email  //email
			);
			
			return 
				new MKK_SiteAccessTicket(user, sessionId);
		}
		
		if( SIDString.length >= SIDStrMinSize )
		{	auto dbase = new DBPostgreSQL(_authDBConnStr);
		
			if( (dbase is null) || !dbase.isConnected )
				return createTicket();
			
			sessionId = verifySessionId( SIDString, dbase );
			
			if( sessionId == SessionIdType.init )
				return createTicket();
			//TODO: Добавить проверку, что у нас корректный Ид сессии
			
			//Делаем запрос к БД за информацией о пользователе
			auto query_res = dbase.query(
				` select U.login, U.user_group, U.name, U.email `
				` from session `
				` join site_user as U `
				` on U.num = site_user_num `
				` where session.num = '` 
				~ webtank.common.conv.toHexString( sessionId ) ~ `'::uuid;`
			);
			
			if( (query_res.recordCount != 1) && (query_res.fieldCount != 4) )
				return createTicket();
			
			//Получаем информацию о пользователе из результата запроса
			login = query_res.get(0, 0, null); //login
			group = query_res.get(1, 0, null); //group
			name = query_res.get(2, 0, null);  //name
			email = query_res.get(3, 0, null);  //email
		}
		return createTicket();
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	IAccessTicket authenticate(string login, string password)
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
			return null;
			
		if( login.length < loginMinLength ) //Проверяем длину логина
			return null;
		
		//Делаем запрос к БД за информацией о пользователе
		auto query_res = dbase.query(
			` select num, password, user_group, name, email `
			` from site_user `
			` where login='`
			~ PGEscapeStr( login ) ~ `';`
		);
		
		if( ( query_res.recordCount != 1 ) || ( query_res.fieldCount != 5 ) )
			return null;
			
		string user_id = query_res.get(0, 0, null);
		string found_password = query_res.get(1, 0, null);
		string group = query_res.get(2, 0, null);
		string name = query_res.get(3, 0, null);
		string email = query_res.get(4, 0, null);
		
		try { //Логирование запросов к БД для отладки
			import std.file;
			std.file.append( _errorLogFile, 
				"--------------------\r\n"
				"Authentication.enterUser()\r\n"
				"user_id: " ~ user_id 
				~ ";  name: " ~ name ~ "\r\n"
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
				` insert into "session" ("num", "site_user_num", "expires") values ( ( '`
				~ sidStr ~ `' )::uuid, ` ~ PGEscapeStr( user_id  )
				~ `, ( current_timestamp + interval '` 
				~ PGEscapeStr( _sessionLifetime.to!string ) ~ ` minutes' )  )`
				~ ` returning 'authenticated';`;
			auto newSIDStatusRes = dbase.query(query);
			if( newSIDStatusRes.recordCount != 1 )
				return null;
			string statusStr = newSIDStatusRes.get(0, 0, "");
			
			if( statusStr == "authenticated" )
			{	auto user = new MKK_SiteUser( login, group, name, email );
				return 
					new MKK_SiteAccessTicket( user, sid );
				//Аутентификация завершена успешно
			}
		}
		
		return null;
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
		where num = '` ~ SIDString ~ `'::uuid and current_timestamp < "expires";`
	);
	
	//К БД подключились
	if( ( query_res.recordCount == 1 ) && ( query_res.fieldCount == 1 ) )
		return SID; 
	else
		return SessionIdType.init; //Нет записей
}
