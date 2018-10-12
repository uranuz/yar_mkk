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
enum size_t sessionLifetime = 180; //Время жизни сессии в минутах
enum size_t emailConfirmDaysLimit = 3;  // Время на подтверждение адреса электронной почты пользователем

/// Класс управляет выдачей билетов для доступа
class MKKMainAccessController: IAccessController
{
protected:
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
		//debug import std.stdio: writeln;
		//debug writeln(`TRACE authenticate 1`);
		if( auto httpCtx = cast(HTTPContext) context )
		{
			//debug writeln(`TRACE authenticate 2`);
			return authenticateSession(httpCtx);
		}
		//debug writeln(`TRACE authenticate 2`);
		return new AnonymousUser;
	}

	///Метод выполняет аутентификацию сессии для HTTP контекста
	///Возвращает удостоверение пользователя
	IUserIdentity authenticateSession(HTTPContext context)
	{
		//debug import std.stdio: writeln;
		import std.conv: text;
		auto req = context.request;
		string SIDString = req.cookies.get("__sid__", null);

		//debug writeln(`TRACE authenticateSession 1`);
		if( SIDString.length != sessionIdStrLength )
			return new AnonymousUser;
		//debug writeln(`TRACE authenticateSession 2`);

		SessionId sessionId;
		Base64URL.decode(SIDString, sessionId[]);

		if( sessionId == SessionId.init )
			return new AnonymousUser;
		//debug writeln(`TRACE authenticateSession 3`);

		//Делаем запрос к БД за информацией о сессии
		auto sidQueryRes = _getAuthDB().query(
			//Получим адрес машины и тип клиентской программы, если срок действия не истек или ничего
`select client_address, user_agent
from session
where
	sid = '` ~ Base64URL.encode(sessionId) ~ `'
	and current_timestamp at time zone 'UTC' <= (created + '` ~ sessionLifetime.text ~ ` minutes')`
		);

		if( sidQueryRes.recordCount != 1 || sidQueryRes.fieldCount != 2 )
			return new AnonymousUser;
		//debug writeln(`TRACE authenticateSession 4`);

		//Проверяем адрес и клиентскую программу с имеющимися при создании сессии
		if(
			req.headers.get("x-real-ip", null) != sidQueryRes.get(0, 0, null) ||
			req.headers.get("user-agent", null) != sidQueryRes.get(1, 0, null)
		) {
			return new AnonymousUser;
		}
		//debug writeln(`TRACE authenticateSession 5`);

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
	su.num, su.email, su.login, su.name,
	to_json(coalesce(
		array_agg(R.name) filter(where nullif(R.name, '') is not null), ARRAY[]::text[]
	)) "roles"
from session
join site_user su
	on su.num = site_user_num
left join user_access_role UR
	on UR.user_num = su.num
left join access_role R
	on R.num = UR.role_num
where session.sid = '` ~ Base64URL.encode(sessionId) ~ `'
	and su.is_blocked is not true
group by su.num, su.email, su.login, su.name`
		).getRecordSet(userDataRecFormat);

		if( !userRS.length )
			return new AnonymousUser;
		//debug writeln(`TRACE authenticateSession 6`);
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
			string[], "roles",
			size_t, "tourist_num"
		)();

		//Делаем запрос к БД за информацией о пользователе
		auto userRS = _getAuthDB().query(
`select
	su.num, su.pw_hash, su.pw_salt, su.reg_timestamp, su.name, su.email,
	to_json(coalesce(
		array_agg(R.name) filter(where nullif(R.name, '') is not null), ARRAY[]::text[]
	)) "roles",
	su.tourist_num
from site_user su
left join user_access_role UR
	on UR.user_num = su.num
left join access_role R
	on R.num = UR.role_num
where login = '` ~ PGEscapeStr(login) ~ `'
	and su.is_blocked is not true
group by su.num, su.pw_hash, su.pw_salt, su.reg_timestamp, su.name, su.email`
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
		string touristNum = userRec.getStr!"tourist_num";

		bool isValidPassword = checkPassword(validEncodedPwHash, password, pwSalt, regDateTime.toISOExtString());

		if( isValidPassword )
		{
			SessionId sid = generateSessionId(login, rolesStr, Clock.currTime().toISOString());

			auto newSIDStatusRes = _getAuthDB().query(
`insert into "session" (
	"sid", "site_user_num", "created", "client_address", "user_agent"
)
values(
	'` ~ Base64URL.encode(sid) ~ `',
	`  ~ PGEscapeStr(userNum) ~ `,
	current_timestamp at time zone 'UTC',
	'` ~ PGEscapeStr(clientAddress) ~ `',
	'` ~ PGEscapeStr(userAgent) ~ `'
)
returning 'authenticated'`
			);

			if( newSIDStatusRes.recordCount != 1 )
				return new AnonymousUser;

			if( newSIDStatusRes.get(0, 0, null) == "authenticated" )
			{
				string[string] userData = [
					"userNum": userNum,
					"roles": rolesStr,
					"email": email,
					"touristNum": touristNum
				];
				//Аутентификация завершена успешно
				return new MKKUserIdentity(login, name, userRec.get!"roles"(), userData, sid);
			}
		}

		return new AnonymousUser;
	}

	// Эта обертка над authenticateByPassword получает некоторые параметры из контекста.
	// Выполняет аутентификацию, устанавливает идентификатор сессии в Cookie запроса и ответа,
	// устанавливает св-во user в контексте
	IUserIdentity authenticateByPassword(HTTPContext ctx, string login, string password)
	{
		import std.base64: Base64URL;

		IUserIdentity userIdentity = authenticateByPassword(
			login,
			password,
			ctx.request.headers[`x-real-ip`],
			ctx.request.headers[`user-agent`]
		);
		MKKUserIdentity mkkIdentity = cast(MKKUserIdentity) userIdentity;
		if( mkkIdentity !is null )
		{
			string sidStr = Base64URL.encode(mkkIdentity.sessionId) ;
			ctx.request.cookies[`__sid__`] = sidStr;
			ctx.response.cookies[`__sid__`] = sidStr;
		}
		else
		{
			// Удаляем возможный старый __sid__, если не удалось получить
			ctx.request.cookies[`__sid__`] = null;
			ctx.response.cookies[`__sid__`] = null;
		}
		// Проставляем path (только для заголовка ответа), чтобы не было случайностей
		ctx.response.cookies[`__sid__`].path = "/";

		// Для удобства установим логин пользователя
		ctx.request.cookies[`user_login`] = userIdentity.id;
		ctx.response.cookies[`user_login`] = userIdentity.id;
		ctx.response.cookies[`user_login`].path = "/";
		ctx.user = userIdentity; 
		return userIdentity;
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
