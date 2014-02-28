module mkk_site.access_control;

import std.conv, std.digest.digest, std.datetime, std.base64 : Base64URL;

import webtank.db.postgresql, webtank.net.utils, webtank.security.access_control, webtank.net.http.context, webtank.common.conv, webtank.common.crypto_scrypt;

import mkk_site.site_data;

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

class MKK_SiteUser: AnonymousUser
{
	this( 
		string login, string name,
		string group, string[string] data, 
		ref const(SessionId) sid
	)
	{	_login = login;
		_name = name;
		_group = group;
		_data = data;
		_sessionId = sid;
	}
	
	override {
		///Строка для идентификации пользователя
		string id() @property
		{	return _login; }
		
		///Публикуемое имя пользователя
		string name() @property
		{	return _name; }
		
		///Дополнительные данные пользователя
		const(char[])[string] data()
		{	return _data; }
		
		///Возвращает true, если владелец успешно прошёл проверку подлинности. Иначе false
		bool isAuthenticated() @property
		{	return ( ( _sessionId != SessionId.init ) /+&& ( _userInfo != anonymousUI )+/  ); //TODO: Улучшить проверку
		}
		
		///Функция возвращает true, если пользователь входит в группу
		bool isInRole( string roleName )
		{	return ( roleName == _group ); }
	}
	
	///Идентификатор сессии
	ref const(SessionId) sessionId() @property
	{	return _sessionId; }
	
protected:
	SessionId _sessionId; 
	string _login;
	string _group;
	string _name;
	string[string] _data;
}

///Класс управляет выдачей билетов для доступа
class MKK_SiteAccessController: IAccessController
{
protected:
	immutable(size_t) _sessionLifetime = 60; //Время жизни сессии в минутах

public:
	///Реализация метода аутентификации контролёра доступа
	override IUserIdentity authenticate(Object context)
	{	auto httpCtx = cast(HTTPContext) context;
		
		if( httpCtx is null )
			return new AnonymousUser;
		else
			return authenticateSession(httpCtx);
	}

	///Метод выполняет аутентификацию сессии для HTTP контекста
	///Возвращает удостоверение пользователя
	IUserIdentity authenticateSession(HTTPContext context)
	{
		string SIDString = context.request.cookie.get( "__sid__", null );
		
		SessionId sessionId;
		
		if( SIDString.length != sessionIdStrLength )
			return new AnonymousUser;
			
		auto dbase = new DBPostgreSQL(authDBConnStr);
		
		if( !dbase.isConnected )
			return new AnonymousUser;
		
		Base64URL.decode(SIDString, sessionId[]);
		
		if( sessionId == SessionId.init )
			return new AnonymousUser;
		
		//Делаем запрос к БД за информацией о сессии
		auto session_QRes = dbase.query(
			//Получим адрес машины и тип клиентской программы, если срок действия не истек или ничего
			` select client_address, user_agent from session `
			~ ` where sid = '` ~ Base64URL.encode( sessionId ) ~ `' and current_timestamp < "expires";`
		);
		
		if( session_QRes.recordCount != 1 || session_QRes.fieldCount != 2 )
			return new AnonymousUser;
		
		//Проверяем адрес и клиентскую программу с имеющимися при создании сессии
		if( context.request.remoteAddress.toAddrString() != session_QRes.get(0, 0, "") ||
			context.request.headers.get("user-agent", "") != session_QRes.get(1, 0, "")
		) return new AnonymousUser;
		
		//Делаем запрос к БД за информацией о пользователе
		auto user_QRes = dbase.query(
			` select U.num, U.email, U.login, U.name, U.user_group `
			` from session `
			` join site_user as U `
			` on U.num = site_user_num `
			` where session.sid = '` 
			~ Base64URL.encode( sessionId ) ~ `';`
		);
		
		if( (user_QRes.recordCount != 1) && (user_QRes.fieldCount != 5) )
			return new AnonymousUser;
		
		string[string] userData = [ 
			"user_num": user_QRes.get(0, 0, null), 
			"email": user_QRes.get(1, 0, null)
		];
		
		//Получаем информацию о пользователе из результата запроса
		return new MKK_SiteUser(
			user_QRes.get(2, 0, null), //login
			user_QRes.get(3, 0, null),  //name
			user_QRes.get(4, 0, null), //group
			userData,
			sessionId
		);
	}
	
	//Функция выполняет вход пользователя с логином и паролем, 
	//происходит генерация Ид сессии, сохранение его в БД
	IUserIdentity authenticateByPassword(
		string login, 
		string password,
		string clientAddress,
		string userAgent
	)
	{	auto dbase = new DBPostgreSQL(authDBConnStr);
		if( !dbase.isConnected )
			return new AnonymousUser;
			
		string group;
		string name;
		string email;
		
		if( login.length < minLoginLength || password.length < minPasswordLength )
			return new AnonymousUser;
		
		//Делаем запрос к БД за информацией о пользователе
		auto query_res = dbase.query(
			` select num, pw_hash, pw_salt, reg_timestamp, user_group, name, email `
			` from site_user `
			` where login='`
			~ PGEscapeStr( login ) ~ `';`
		);
		
		if( query_res.recordCount != 1 || query_res.fieldCount != 7 )
			return new AnonymousUser;
			
		string userNum = query_res.get(0, 0, null);
		string validEncodedPwHash = query_res.get(1, 0, null);
		string pwSalt = query_res.get(2, 0, null);
		string regTimestampStr = query_res.get(3, 0, null);
		
		DateTime regDateTime = DateTimeFromPGTimestamp( regTimestampStr );
		
		group = query_res.get(4, 0, null);
		name = query_res.get(5, 0, null);
		email = query_res.get(6, 0, null);
		
		bool isValidPassword = checkPassword( validEncodedPwHash, password, pwSalt, regDateTime.toISOExtString() );

		if( isValidPassword ) 
		{	SessionId sid = generateSessionId( login, group, Clock.currTime().toISOString() );
			
			auto newSIDStatusRes = dbase.query(
				` insert into "session" ` 
				~ ` ( "sid", "site_user_num", "expires", "client_address", "user_agent" ) ` 
				~ ` values( '` ~ Base64URL.encode(sid) ~ `', ` ~ PGEscapeStr( userNum )
				~ `, ( current_timestamp + interval '` 
				~ PGEscapeStr( _sessionLifetime.to!string ) ~ ` minutes' ), ` 
				~ `'` ~ PGEscapeStr(clientAddress) ~ `', '` ~ PGEscapeStr(userAgent) ~ `' ) `
				~ ` returning 'authenticated';`
			);
			
			if( newSIDStatusRes.recordCount != 1 )
				return new AnonymousUser;
			
			if( newSIDStatusRes.get(0, 0, "") == "authenticated" )
			{	string[string] userData = [ "user_num": userNum, "email": email ];
				//Аутентификация завершена успешно
				return new MKK_SiteUser( 
					login, name, group, userData, sid
				);
			}
		}
		
		return new AnonymousUser;
	}
}

//Служебная функция для генерации Ид сессии
SessionId generateSessionId( const(char)[] login, const(char)[] group, const(char)[] dateString )
{	auto idSource = login ~ "::" ~ dateString ~ "::" ~ group; //Создаём исходную строку
	SessionId sessionId;
	SHA384( cast(const(ubyte)*) idSource.ptr, idSource.length, sessionId.ptr );
	return sessionId; //Возвращаем идентификатор сессии
}

import std.datetime, std.random, core.thread;

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