module mkk_site.security.core.access_control;

import std.conv, std.digest.digest, std.datetime, std.utf, std.base64 : Base64URL;

import
	webtank.db.database,
	webtank.net.utils,
	webtank.security.access_control,
	webtank.net.http.context,
	webtank.common.conv;

public import mkk_site.security.common.user_identity;

import mkk_site.security.common.session_id;
import mkk_site.security.core.crypto;

enum uint minLoginLength = 3;  //Минимальная длина логина
enum uint minPasswordLength = 8;  //Минимальная длина пароля

/// Класс управляет выдачей билетов для доступа
class MKKMainAccessController: IAccessController
{
protected:
	static immutable size_t _sessionLifetime = 180; //Время жизни сессии в минутах
	IDatabase delegate() _getAuthDB;

public:
	this(IDatabase delegate() getAuthDB)
	{
		assert(getAuthDB, `Auth DB method reference is null!!!`);
		_getAuthDB = getAuthDB;
	}

	///Реализация метода аутентификации контролёра доступа
	override IUserIdentity authenticate(Object context)
	{
		if( auto httpCtx = cast(HTTPContext) context ) {
			return authenticateSession(httpCtx);
		}
		return new AnonymousUser;
	}

	///Метод выполняет аутентификацию сессии для HTTP контекста
	///Возвращает удостоверение пользователя
	IUserIdentity authenticateSession(HTTPContext context)
	{
		auto req = context.request;
		string SIDString = req.cookies.get("__sid__", null);

		if( SIDString.length != sessionIdStrLength )
			return new AnonymousUser;

		SessionId sessionId;
		Base64URL.decode(SIDString, sessionId[]);

		if( sessionId == SessionId.init )
			return new AnonymousUser;

		//Делаем запрос к БД за информацией о сессии
		auto sidQueryRes = _getAuthDB().query(
			//Получим адрес машины и тип клиентской программы, если срок действия не истек или ничего
			`select client_address, user_agent from session where sid = '`
			~ Base64URL.encode(sessionId) ~ `' and current_timestamp < "expires";`
		);

		if( sidQueryRes.recordCount != 1 || sidQueryRes.fieldCount != 2 )
			return new AnonymousUser;

		//Проверяем адрес и клиентскую программу с имеющимися при создании сессии
		if(
			req.headers.get("x-real-ip", null) != sidQueryRes.get(0, 0, null) ||
			req.headers.get("user-agent", null) != sidQueryRes.get(1, 0, null)
		) {
			return new AnonymousUser;
		}

		import webtank.datctrl.record_format: RecordFormat, PrimaryKey;
		import webtank.db.datctrl_joint: getRecordSet;
		static immutable userDataRecFormat = RecordFormat!(
			PrimaryKey!(size_t), "num",
			string, "email",
			string, "login",
			string, "name",
			string[], "roles"
		)();

		//Делаем запрос к БД за информацией о пользователе
		auto userRS = _getAuthDB().query(
`select
	U.num, U.email, U.login, U.name,
	to_json(coalesce(
		array_agg(R.name) filter(where nullif(R.name, '') is not null), ARRAY[]::text[]
	)) "roles"
from session
join site_user U
	on U.num = site_user_num
left join user_access_role UR
	on UR.user_num = U.num
left join access_role R
	on R.num = UR.role_num
where session.sid = '` ~ Base64URL.encode(sessionId) ~ `'
group by U.num, U.email, U.login, U.name`
		).getRecordSet(userDataRecFormat);

		if( !userRS.length )
			return new AnonymousUser;
		auto userRec = userRS.front;

		string[string] userData = [
			"userNum": userRec.getStr!"num",
			"email": userRec.getStr!"email"
		];

		import std.array: join;
		//Получаем информацию о пользователе из результата запроса
		return new MKKUserIdentity(
			userRec.getStr!"login",
			userRec.getStr!"name",
			userRec.get!"roles"(),
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
	) {
		if( login.count < minLoginLength || password.count < minPasswordLength )
			return new AnonymousUser;

		import webtank.datctrl.record_format: RecordFormat, PrimaryKey;
		import webtank.db.datctrl_joint: getRecordSet;
		static immutable userPwDataRecFormat = RecordFormat!(
			PrimaryKey!(size_t), "num",
			string, "pwHash",
			string, "pwSalt",
			DateTime, "regTimestamp",
			string, "name",
			string, "email",
			string[], "roles"
		)();

		//Делаем запрос к БД за информацией о пользователе
		auto userRS = _getAuthDB().query(
`select
	U.num, U.pw_hash, U.pw_salt, U.reg_timestamp, U.name, U.email,
	to_json(coalesce(
		array_agg(R.name) filter(where nullif(R.name, '') is not null), ARRAY[]::text[]
	)) "roles"
from site_user U
left join user_access_role UR
	on UR.user_num = U.num
left join access_role R
	on R.num = UR.role_num
where login = '` ~ PGEscapeStr(login) ~ `'
group by U.num, U.pw_hash, U.pw_salt, U.reg_timestamp, U.name, U.email`
		).getRecordSet(userPwDataRecFormat);

		if( !userRS.length )
			return new AnonymousUser;

		auto userRec = userRS.front;


		string userNum = userRec.getStr!"num";
		string validEncodedPwHash = userRec.getStr!"pwHash";
		string pwSalt = userRec.getStr!"pwSalt";
		DateTime regDateTime = userRec.get!"regTimestamp";

		import std.array: join;
		string rolesStr = userRec.get!"roles"().join(`;`);
		string name = userRec.getStr!"name";
		string email = userRec.getStr!"email";

		bool isValidPassword = checkPassword(validEncodedPwHash, password, pwSalt, regDateTime.toISOExtString());

		if( isValidPassword )
		{
			SessionId sid = generateSessionId(login, rolesStr, Clock.currTime().toISOString());

			auto newSIDStatusRes = _getAuthDB().query(
				` insert into "session" `
				~ ` ( "sid", "site_user_num", "expires", "client_address", "user_agent" ) `
				~ ` values( '` ~ Base64URL.encode(sid) ~ `', ` ~ PGEscapeStr(userNum)
				~ `, ( current_timestamp + interval '`
				~ PGEscapeStr(_sessionLifetime.to!string) ~ ` minutes' ), `
				~ `'` ~ PGEscapeStr(clientAddress) ~ `', '` ~ PGEscapeStr(userAgent) ~ `' ) `
				~ ` returning 'authenticated';`
			);

			if( newSIDStatusRes.recordCount != 1 )
				return new AnonymousUser;

			if( newSIDStatusRes.get(0, 0, null) == "authenticated" )
			{
				string[string] userData = [
					"userNum": userNum,
					"roles": rolesStr,
					"email": email
				];
				//Аутентификация завершена успешно
				return new MKKUserIdentity(login, name, userRec.get!"roles"(), userData, sid);
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
		_getAuthDB().query(
			`delete from session where "site_user_num" = ` ~ userNum.to!string ~ `;`
		);

		mkkUserIdentity.invalidate(); // Затираем текущий экземпляр удостоверения

		return true;
	}
}

bool changeUserPassword(bool doPwCheck = true)(
	IDatabase delegate() _getAuthDB,
	string login,
	string oldPassword,
	string newPassword
) {
	assert(_getAuthDB, `getAuthDB method is not specified!`);
	// import mkk_site.logging: SiteLoger; TODO: Устаревшая вещь - нужно переделать

	// SiteLoger.info( `Проверка длины нового пароля`, `Смена пароля пользователя` );
	if( newPassword.length < minPasswordLength )
	{
		// SiteLoger.info( `Новый пароль слишком короткий`, `Смена пароля пользователя` );
		return false;
	}

	// SiteLoger.info( `Подключаемся к базе данных аутентификации`, `Смена пароля пользователя` );
	// SiteLoger.info( `Получаем данные о пользователе из БД`, `Смена пароля пользователя` );
	auto userQueryRes = _getAuthDB().query(
`select num, pw_hash, pw_salt, reg_timestamp
from site_user
where login = '` ~ PGEscapeStr( login ) ~ `';`
	);
	// SiteLoger.info( `Запрос данных о пользователе успешно завершен`, `Смена пароля пользователя` );

	import webtank.common.conv: fromPGTimestamp;
	DateTime regDateTime = fromPGTimestamp!DateTime(userQueryRes.get(3, 0, null));
	string regTimestampStr = regDateTime.toISOExtString();

	static if( doPwCheck )
	{
		string oldPwHashStr = userQueryRes.get(1, 0, null);
		string oldPwSaltStr = userQueryRes.get(2, 0, null);

		// SiteLoger.info( `Проверка старого пароля пользователя`, `Смена пароля пользователя` );
		if( !checkPassword(oldPwHashStr, oldPassword, oldPwSaltStr, regTimestampStr) )
		{
			// SiteLoger.info( `Неверный старый пароль`, `Смена пароля пользователя` );
			return false;
		}
		// SiteLoger.info( `Проверка старого пароля успешно завершилась`, `Смена пароля пользователя` );
	}

	import std.uuid : randomUUID;
	string pwSaltStr = randomUUID().toString();

	ubyte[] pwHash = makePasswordHash(newPassword, pwSaltStr, regTimestampStr);
	string pwHashStr = encodePasswordHash(pwHash);

	// SiteLoger.info( `Выполняем запрос на смену пароля`, `Смена пароля пользователя` );
	auto changePwQueryRes = _getAuthDB().query(
`update site_user set pw_hash = '` ~ PGEscapeStr(pwHashStr) ~ `', pw_salt = '` ~ PGEscapeStr(pwSaltStr) ~ `'
where login = '` ~ PGEscapeStr(login) ~ `'
returning 'pw_changed';`
	);

	// SiteLoger.info( `Проверка успешности выполнения запроса смены пароля`, `Смена пароля пользователя` );
	if( changePwQueryRes.get(0, 0, null) == "pw_changed" )
	{
		// SiteLoger.info( `Успешно задан новый пароль`, `Смена пароля пользователя` );
		return true;
	}
	// SiteLoger.info( `Запрос смены пароля завершился с неверным результатом`, `Смена пароля пользователя` );

	return false;
}
