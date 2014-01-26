module mkk_site.authentication;

import std.conv, std.digest.digest, std.datetime, std.base64 : Base64URL;

import webtank.db.postgresql, webtank.net.utils, webtank.net.access_control, webtank.net.connection, webtank.net.http.context, webtank.common.conv, webtank.common.crypto_scrypt;

import deimos.openssl.sha;

pragma(lib, "crypto");
pragma(lib, "ssl");
pragma(lib, "/usr/local/lib/libtarsnap.a");

//Класс исключения в аутентификации
class AuthException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
		//message = msg ~ "  <" ~ file ~ ", " ~ line.to!string ~ ">";
	}
}

enum uint sessionIdByteLength = 48; //Количество байт в ИД - сессии
enum uint sessionIdStrLength = sessionIdByteLength * 8 / 6;  //Длина в символах в виде base64 - строки
alias ubyte[sessionIdByteLength] SessionId; //Тип: ИД сессии

enum uint minLoginLength = 3;  //Минимальная длина логина
enum uint minPasswordLength = 8;  //Минимальная длина пароля

enum uint pwHashByteLength = 72; //Количество байт в хэше пароля
enum uint pwHashStrLength = pwHashByteLength * 8 / 6; //Длина в символах в виде base64 - строки
//alias ubyte[pwHashByteLength] PasswordHash;

enum scryptN = 1024;
enum scryptR = 8;
enum scryptP = 1;

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
	this( IUser user, SessionId sessionId )
	{	_user = user; 
		_sessionId = sessionId;
	}
	
	///Пользователь-владелец карты
	override IUser user() @property
	{	return _user; }
	
	///Возвращает true, если владелец успешно прошёл проверку подлинности. Иначе false
	override bool isAuthenticated() @property
	{	return ( ( _sessionId != SessionId.init ) /+&& ( _userInfo != anonymousUI )+/  ); //TODO: Улучшить проверку
	}
	
	//свойство "Ид сессии"
	SessionId sessionId() @property
	{	return _sessionId; }
	
protected:
	SessionId _sessionId;  //Ид сессии
	IUser _user;
}

///Класс управляет выдачей билетов для доступа
class MKK_SiteAccessTicketManager: IAccessTicketManager
{	
protected:
	immutable(size_t) _sessionLifetime = 60; //Время жизни сессии в минутах
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
		
		writeln("getTicket test 10");
		
		if( ctx is null || ctx.request is null || ctx.request.cookie is null  )
			return null;
		
		string SIDString = ctx.request.cookie.get( "__sid__", null );
		
		string login;
		string group;
		string name;
		string email;
		
		writeln("getTicket test 20");
		
		SessionId sessionId;
		
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
		
		writeln("getTicket test 30");
		
		if( SIDString.length == sessionIdStrLength )
		{	auto dbase = new DBPostgreSQL(_authDBConnStr);
		
			if( (dbase is null) || !dbase.isConnected )
				return createTicket();
				
			writeln("getTicket test 40");
			
			sessionId = verifySessionId( SIDString, dbase );
			
			writeln("getTicket test 50");
			
			if( sessionId == SessionId.init )
				return createTicket();
			//TODO: Добавить проверку, что у нас корректный Ид сессии
			
			//Делаем запрос к БД за информацией о пользователе
			auto query_res = dbase.query(
				` select U.login, U.user_group, U.name, U.email `
				` from session `
				` join site_user as U `
				` on U.num = site_user_num `
				` where session.sid = '` 
				~ Base64URL.encode( sessionId ) ~ `';`
			);
			
			writeln("getTicket test 60");
			
			if( (query_res.recordCount != 1) && (query_res.fieldCount != 4) )
				return createTicket();
			
			//Получаем информацию о пользователе из результата запроса
			login = query_res.get(0, 0, null); //login
			group = query_res.get(1, 0, null); //group
			name = query_res.get(2, 0, null);  //name
			email = query_res.get(3, 0, null);  //email
			
			writeln("getTicket test 70");
		}
		return createTicket();
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	MKK_SiteAccessTicket authenticate(
		string login, 
		string password,
		string clientAddress,
		string userAgent
	)
	{	
		auto dbase = new DBPostgreSQL(_authDBConnStr);
		if( dbase is null || !dbase.isConnected )
			return null;
			
		string group;
		string name;
		string email;
		
		auto makeInvalidTicket()
		{	return
				new MKK_SiteAccessTicket(  
					new MKK_SiteUser( login, group, name, email ),
					SessionId.init //Задаём некорректный идентификатор
				);
		}
		
		if( login.length < minLoginLength || password.length < minPasswordLength )
			return 
				makeInvalidTicket();
		//	throw new AuthException("Длина логина или пароля меньше минимально разрешённой!!!");
			
		if( login.length < minLoginLength ) //Проверяем длину логина
			return 
				makeInvalidTicket();
		
		//Делаем запрос к БД за информацией о пользователе
		auto query_res = dbase.query(
			` select num, pw_hash, pw_salt, reg_timestamp, user_group, name, email `
			` from site_user `
			` where login='`
			~ PGEscapeStr( login ) ~ `';`
		);
		
		if( query_res.recordCount != 1 || query_res.fieldCount != 7 )
			return 
				makeInvalidTicket();
			
		string userId = query_res.get(0, 0, null);
		string validEncodedPwHash = query_res.get(1, 0, null);
		string pwSalt = query_res.get(2, 0, null);
		string regTimestampStr = query_res.get(3, 0, null)[0..19];
		
		DateTime regDateTime = DateTimeFromPGTimestamp( regTimestampStr );
		
		group = query_res.get(4, 0, null);
		name = query_res.get(5, 0, null);
		email = query_res.get(6, 0, null);
		
		bool isValidPassword = checkPassword( validEncodedPwHash, password, pwSalt, regDateTime.toISOExtString() );

		//Проверка пароля
		if( isValidPassword ) 
		{	//TODO: Генерировать уникальный идентификатор сессии и возвращать
			
			SessionId sid = generateSessionId( login, group, Clock.currTime().toISOString() );
			
			auto newSIDStatusRes = dbase.query(
				` insert into "session" ` 
				~ ` ( "sid", "site_user_num", "expires", "client_address", "user_agent" ) ` 
				~ ` values( '` ~ Base64URL.encode(sid) ~ `', ` ~ PGEscapeStr( userId )
				~ `, ( current_timestamp + interval '` 
				~ PGEscapeStr( _sessionLifetime.to!string ) ~ ` minutes' ), ` 
				~ `'` ~ PGEscapeStr(clientAddress) ~ `', '` ~ PGEscapeStr(userAgent) ~ `' ) `
				~ ` returning 'authenticated';`
			);
			
			if( newSIDStatusRes.recordCount != 1 )
				return 
					makeInvalidTicket();
			string statusStr = newSIDStatusRes.get(0, 0, "");
			
			if( statusStr == "authenticated" )
				return //Аутентификация завершена успешно
					new MKK_SiteAccessTicket(  
						new MKK_SiteUser( login, group, name, email ),
						sid
					);
		}
		
		return
			makeInvalidTicket();
	}
}

//Служебная функция для генерации Ид сессии
SessionId generateSessionId( const(char)[] login, const(char)[] group, const(char)[] dateString )
{	auto idSource = login ~ "::" ~ dateString ~ "::" ~ group; //Создаём исходную строку
	SessionId pwHash;
	SHA384( cast(const(ubyte)*) idSource.ptr, idSource.length, pwHash.ptr);
	return pwHash; //Возвращаем идентификатор сессии
}

//Служебная проверки и получения идентификатора сессии
SessionId verifySessionId(string SIDString, DBPostgreSQL dbase)
{	
	if( dbase is null || !dbase.isConnected )
		return SessionId.init; //Не доступа к базе
		
	writeln("verifySessionId test 10");
		
	//Прерываем, если нет Ид сессии нет в браузере
	if( SIDString.length < sessionIdStrLength ) 
		return SessionId.init;
		
	writeln("verifySessionId test 20");
	
	import webtank.common.conv;
	SessionId SID; 
	Base64URL.decode(SIDString, SID[]);
	
	writeln("verifySessionId test 30");
	
	if( SID == SessionId.init )
		return SessionId.init;
	SIDString = Base64URL.encode( SID );  //Важно
	
	writeln("verifySessionId test 40");
	
	//Делаем запрос к БД за информацией о сессии
	auto query_res = dbase.query(
		//Получим 1, если срок действия не истек или ничего
		`select 1 from session 
		where sid = '` ~ SIDString ~ `' and current_timestamp < "expires";`
	);
	
	writeln("verifySessionId test 50");
	
	//К БД подключились
	if( ( query_res.recordCount == 1 ) && ( query_res.fieldCount == 1 ) )
		return SID; 
	else
		return SessionId.init; //Нет записей
}

import std.stdio, std.datetime, std.random, core.thread;

///Генерирует хэш для пароля с "солью" и "перцем"
ubyte[] makePasswordHash( 
	const(char)[] password, const(char)[] salt, const(char)[] pepper, 
	size_t hashByteLength = pwHashByteLength,
	ulong N = scryptN, uint r = scryptR, uint p = scryptP  )
{	ubyte[] pwHash = new ubyte[hashByteLength];
	
	auto secret = password ~ pepper;
	auto spice = pepper ~ salt;

	int result = crypto_scrypt(
		cast(const(ubyte)*) secret.ptr, secret.length,
		cast(const(ubyte)*) spice.ptr, spice.length,
		N, r, p, pwHash.ptr, hashByteLength
	);
	
	if( result != 0 )
		throw new AuthException("Cannot make password hash!!!");
	
	return pwHash;
}

///Кодирует хэш пароля для хранения в виде строки
string encodePasswordHash( const(ubyte[]) pwHash, ulong N = scryptN, uint r = scryptR, uint p = scryptP )
{	return ( "scr$" ~ Base64URL.encode(pwHash) ~ "$" ~ pwHash.length.to!string
		~ "$" ~ N.to!string ~ "$" ~ r.to!string ~ "$" ~ p.to!string ).idup;
}

import std.array;

///Проверяет пароль на соответствие закодированному хэшу с заданной солью и перцем
bool checkPassword( const(char)[] encodedPwHash, const(char)[] password, const(char)[] salt, const(char)[] pepper )
{	auto params = encodedPwHash.split("$");

	if( params.length != 6 || params[0] != "scr" )
		return false;
	
	ubyte[] pwHash = Base64URL.decode( params[1] );
	if( pwHash.length != params[2].to!size_t )
		return false;
	
	return makePasswordHash( password, salt, pepper, params[2].to!size_t, params[3].to!ulong, params[4].to!uint, params[5].to!uint ) == pwHash;
}

// void main()
// {	string password = "rtghrthggrth";
// 	string salt = "1jyuj11";
// 	string pepper = "pp11ppp6";
// 
// 	auto time = Clock.currTime();
// 	auto hash1 = makePasswordHash(password, salt, pepper);
// 	string encodedHash = encodePasswordHash( hash1 );
// 	writeln( "Hashing time: ", Clock.currTime() - time, ". Encoded hash string:" );
// 	writeln( encodedHash );
// 	writeln( "Password checking returned: ", checkPassword(encodedHash, password, salt, pepper) );
// 	
// 	
// }