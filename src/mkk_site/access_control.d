module mkk_site.access_control;

import std.conv, std.digest.digest, std.datetime, std.utf, std.base64 : Base64URL;

import
	webtank.db.database,
	webtank.net.utils,
	webtank.security.access_control,
	webtank.net.http.context,
	webtank.common.conv,
	webtank.common.crypto_scrypt;

import deimos.openssl.sha;

pragma(lib, "crypto");
pragma(lib, "ssl");
pragma(lib, "/usr/local/lib/libtarsnap.a");

public import mkk_site.user_identity;

//Класс исключения в аутентификации
class AuthException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
		//message = msg ~ "  <" ~ file ~ ", " ~ line.to!string ~ ">";
	}
}

enum uint minLoginLength = 3;  //Минимальная длина логина
enum uint minPasswordLength = 8;  //Минимальная длина пароля

enum uint pwHashByteLength = 72; //Количество байт в хэше пароля
enum uint pwHashStrLength = pwHashByteLength * 8 / 6; //Длина в символах в виде base64 - строки
//alias ubyte[pwHashByteLength] PasswordHash;

enum scryptN = 1024;
enum scryptR = 8;
enum scryptP = 1;

///Класс управляет выдачей билетов для доступа
class MKKMainAccessController(alias getAuthDBMethod): IAccessController
{
protected:
	static immutable(size_t) _sessionLifetime = 180; //Время жизни сессии в минутах

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
		string SIDString = context.request.cookies.get( "__sid__", null );

		SessionId sessionId;

		if( SIDString.length != sessionIdStrLength )
			return new AnonymousUser;

		IDatabase dbase = getAuthDBMethod();

		Base64URL.decode(SIDString, sessionId[]);

		if( sessionId == SessionId.init )
			return new AnonymousUser;

		//Делаем запрос к БД за информацией о сессии
		auto session_QRes = dbase.query(
			//Получим адрес машины и тип клиентской программы, если срок действия не истек или ничего
			`select client_address, user_agent from session where sid = '`
			~ Base64URL.encode( sessionId ) ~ `' and current_timestamp < "expires";`
		);

		if( session_QRes.recordCount != 1 || session_QRes.fieldCount != 2 )
			return new AnonymousUser;

		//Проверяем адрес и клиентскую программу с имеющимися при создании сессии
		if( context.request.headers.get("x-real-ip", "") != session_QRes.get(0, 0, "") ||
			context.request.headers.get("user-agent", "") != session_QRes.get(1, 0, "")
		) return new AnonymousUser;

		//Делаем запрос к БД за информацией о пользователе
		auto user_QRes = dbase.query(
`select U.num, U.email, U.login, U.name, U.user_group
from session
join site_user as U
	on U.num = site_user_num
where session.sid = '` ~ Base64URL.encode( sessionId ) ~ `';`
		);

		if( (user_QRes.recordCount != 1) && (user_QRes.fieldCount != 5) )
			return new AnonymousUser;

		string[string] userData = [
			"userNum": user_QRes.get(0, 0, null),
			"email": user_QRes.get(1, 0, null)
		];

		//Получаем информацию о пользователе из результата запроса
		return new MKKUserIdentity(
			user_QRes.get(2, 0, null), //login
			user_QRes.get(3, 0, null), //name
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
	{
		IDatabase dbase = getAuthDBMethod();

		string group;
		string name;
		string email;

		if( login.count < minLoginLength || password.count < minPasswordLength )
			return new AnonymousUser;

		//Делаем запрос к БД за информацией о пользователе
		auto query_res = dbase.query(
`select num, pw_hash, pw_salt, reg_timestamp, user_group, name, email
from site_user
where login = '` ~ PGEscapeStr(login) ~ `';`
		);

		if( query_res.recordCount != 1 || query_res.fieldCount != 7 )
			return new AnonymousUser;

		string userNum = query_res.get(0, 0, null);
		string validEncodedPwHash = query_res.get(1, 0, null);
		string pwSalt = query_res.get(2, 0, null);
		string regTimestampStr = query_res.get(3, 0, null);

		DateTime regDateTime = DateTimeFromPGTimestamp(regTimestampStr);

		group = query_res.get(4, 0, null);
		name = query_res.get(5, 0, null);
		email = query_res.get(6, 0, null);

		bool isValidPassword = checkPassword( validEncodedPwHash, password, pwSalt, regDateTime.toISOExtString() );

		if( isValidPassword )
		{	SessionId sid = generateSessionId( login, group, Clock.currTime().toISOString() );

			auto newSIDStatusRes = dbase.query(
				` insert into "session" `
				~ ` ( "sid", "site_user_num", "expires", "client_address", "user_agent" ) `
				~ ` values( '` ~ Base64URL.encode(sid) ~ `', ` ~ PGEscapeStr(userNum)
				~ `, ( current_timestamp + interval '`
				~ PGEscapeStr( _sessionLifetime.to!string ) ~ ` minutes' ), `
				~ `'` ~ PGEscapeStr(clientAddress) ~ `', '` ~ PGEscapeStr(userAgent) ~ `' ) `
				~ ` returning 'authenticated';`
			);

			if( newSIDStatusRes.recordCount != 1 )
				return new AnonymousUser;

			if( newSIDStatusRes.get(0, 0, "") == "authenticated" )
			{
				string[string] userData = [ "userNum": userNum, "email": email ];
				//Аутентификация завершена успешно
				return new MKKUserIdentity(login, name, group, userData, sid);
			}
		}

		return new AnonymousUser;
	}

	bool logout(IUserIdentity userIdentity)
	{
		MKKUserIdentity mkkUserIdentity = cast(MKKUserIdentity) userIdentity;

		if( !mkkUserIdentity ) {
			return false;
		}

		if( !mkkUserIdentity.isAuthenticated ) {
			return true;
		}

		size_t userNum;
		try {
			userNum = mkkUserIdentity.data.get(`userNum`, null).to!size_t;
		} catch( ConvException e ) {
			return false;
		}

		// Сносим все сессии пользователя из базы
		getAuthDBMethod().query(
			`delete from session where "site_user_num" = ` ~ userNum.to!string ~ `;`
		);

		mkkUserIdentity.invalidate(); // Затираем текущий экземпляр удостоверения

		return true;
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

bool changeUserPassword(bool doPwCheck = true, alias getAuthDBMethod)( string login, string oldPassword, string newPassword )
{
	// import mkk_site.logging: SiteLoger; TODO: Устаревшая вещь - нужно переделать

	// SiteLoger.info( `Проверка длины нового пароля`, `Смена пароля пользователя` );
	if( newPassword.length < minPasswordLength )
	{
		// SiteLoger.info( `Новый пароль слишком короткий`, `Смена пароля пользователя` );
		return false;
	}

	// SiteLoger.info( `Подключаемся к базе данных аутентификации`, `Смена пароля пользователя` );
	IDatabase dbase = getAuthDBMethod();

	// SiteLoger.info( `Получаем данные о пользователе из БД`, `Смена пароля пользователя` );
	auto userQueryRes = dbase.query(
`select num, pw_hash, pw_salt, reg_timestamp
from site_user
where login = '` ~ PGEscapeStr( login ) ~ `';`
	);
	// SiteLoger.info( `Запрос данных о пользователе успешно завершен`, `Смена пароля пользователя` );

	import webtank.common.conv: DateTimeFromPGTimestamp;
	DateTime regDateTime = DateTimeFromPGTimestamp( userQueryRes.get( 3, 0, null ) );
	string regTimestampStr = regDateTime.toISOExtString();

	static if( doPwCheck )
	{
		string oldPwHashStr = userQueryRes.get( 1, 0, null );
		string oldPwSaltStr = userQueryRes.get( 2, 0, null );

		// SiteLoger.info( `Проверка старого пароля пользователя`, `Смена пароля пользователя` );
		if( !checkPassword( oldPwHashStr, oldPassword, oldPwSaltStr, regTimestampStr ) )
		{
			// SiteLoger.info( `Неверный старый пароль`, `Смена пароля пользователя` );
			return false;
		}
		// SiteLoger.info( `Проверка старого пароля успешно завершилась`, `Смена пароля пользователя` );
	}

	import std.uuid : randomUUID;
	string pwSaltStr = randomUUID().toString();

	ubyte[] pwHash = makePasswordHash( newPassword, pwSaltStr, regTimestampStr );
	string pwHashStr = encodePasswordHash( pwHash );

	// SiteLoger.info( `Выполняем запрос на смену пароля`, `Смена пароля пользователя` );
	auto changePwQueryRes = dbase.query(
`update site_user set pw_hash = '` ~ PGEscapeStr( pwHashStr ) ~ `', pw_salt = '` ~ PGEscapeStr( pwSaltStr ) ~ `'
where login = '` ~ PGEscapeStr( login ) ~ `'
returning 'pw_changed';`
	);

	// SiteLoger.info( `Проверка успешности выполнения запроса смены пароля`, `Смена пароля пользователя` );
	if( changePwQueryRes.get(0, 0, "") == "pw_changed" )
	{
		// SiteLoger.info( `Успешно задан новый пароль`, `Смена пароля пользователя` );
		return true;
	}
	// SiteLoger.info( `Запрос смены пароля завершился с неверным результатом`, `Смена пароля пользователя` );

	return false;
}
