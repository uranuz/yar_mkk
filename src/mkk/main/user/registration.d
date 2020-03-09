module mkk.main.user.registration;

import mkk.main.devkit;

import mkk.history.client;
import mkk.history.common;

import mkk.main.tourist.model;
import mkk.main.tourist.edit: editTourist, requireFieldsForReg;
import mkk.main.user.consts: NEW_USER_ROLE, USER_ROLE;
import mkk.main.tourist.read: readTourist;

import webtank.security.auth.core.register_user: registerUser, addUserRoles, RegUserResult;
import webtank.security.auth.core.consts: emailConfirmDaysLimit, minLoginLength, minPasswordLength;
import webtank.ivy.main_service: MainServiceContext;

shared static this()
{
	MainService.JSON_RPCRouter.join!(readForReg)(`tourist.readForReg`);
	MainService.JSON_RPCRouter.join!(regUser)(`user.register`);
	MainService.JSON_RPCRouter.join!(confirmEmail)(`user.confirmEmail`);
	MainService.JSON_RPCRouter.join!(confirmReg)(`user.confirmReg`);
	MainService.JSON_RPCRouter.join!(lockUser)(`user.lock`);
	MainService.JSON_RPCRouter.join!(unlockUser)(`user.unlock`);

	MainService.pageRouter.joinWebFormAPI!(readForReg)("/api/tourist/readForReg");
	MainService.pageRouter.joinWebFormAPI!(regUser)("/api/user/reg/result");
	MainService.pageRouter.joinWebFormAPI!(confirmEmail)("/api/user/reg/email_confirm");
}

Tuple!(
	IBaseRecord, "tourist",
	Tuple!(
		uint, "minLoginLength",
		uint, "minPasswordLength"
	), "settings",
	bool, "isConfirmedUser"
)
readForReg(HTTPContext ctx, Optional!size_t num)
{
	typeof(return) res;
	res.tourist = readTourist(ctx, num).tourist;
	res.settings = typeof(res.settings)(minLoginLength, minPasswordLength);
	res.isConfirmedUser = _isUserConfirmedForTourist(num);
	return res;
}

struct UserRegData
{
	string login;
	string password;
}

static immutable _checkConfirmedQueryFmt = `
select exists(
	select 1
	from site_user su
	join user_access_role uar
		on uar.user_num = su.num
	join access_role a_role
		on a_role.num = uar.role_num
	where
		%s = $1::integer
		and
		a_role.name != $2::text
	limit 1
)`;

// Проверяет есть ли у туриста уже подтвержденный связанный пользователь
bool _isUserConfirmedForTourist(Optional!size_t num)
{
	import std.format: format;
	return getAuthDB().queryParams(
		_checkConfirmedQueryFmt.format(
			`su.tourist_num`
		), num, NEW_USER_ROLE
	).getScalar!bool();
}

Tuple!(
	size_t, `touristNum`,
	size_t, `userNum`
)
regUser(MainServiceContext ctx, TouristDataToWrite touristData, UserRegData userData)
{
	import webtank.db.transaction: makeTransaction;
	import webtank.security.auth.core.by_password: authByPassword;
	import webtank.db.iface.factory: IDatabaseFactory;

	import std.array: join;
	import std.range: empty;

	string[] nameParts; // Собираем сюда полное имя пользователя
	string userEmail;
	if( touristData.num.isSet )
	{
		// Если мы работаем в режиме использования существующей записи туриста,
		// то: во-первых, не доверяем вводу и берем данные из БД (если кто-то вызовет вручную)
		// во-вторых данные нам и не будут присланы (кроме номера, в нормальном сценарии),
		// т.к. поля в интерфейсе "задисейблены"
		auto touristDBRec = getCommonDB().queryParams(
`select
	num,
	family_name,
	given_name,
	patronymic,
	email
from tourist
where tourist.num = $1::integer`,
		touristData.num).getRecord(RecordFormat!(
			PrimaryKey!(size_t, "num"),
			string, "familyName",
			string, "givenName",
			string, "patronymic",
			string, "email"
		)());
		enforce(
			touristDBRec !is null,
			`Не удалось прочитать информацию о туристе из БД`);
		enforce(
			!_isUserConfirmedForTourist(touristData.num),
			`Регистрация пользователя, связанного с данным туристом, уже подтверждена`);

		string val;
		static foreach( field; [`familyName`, `givenName`, `patronymic`] )
		{
			val = touristDBRec.getStr!(field)();
			if( !val.empty ) {
				nameParts ~= val;
			}
		}

		// Письмо нам надо отослать в любом случае на правильный email...
		// Может быть ситуация, что у записи пользователя не задан email, либо запрещен его показ кому-угодно по правам...
		// Либо там записан устаревший бред, который уже ничему не соответствует.
		// Разрешим пользователю передать актуальный адрес из формы... Если нет, то возьмем уже из БД
		userEmail = (touristData.email.isSet && !touristData.email.value.empty)? touristData.email.value: touristDBRec.getStr!(`email`)();
	}
	else
	{
		requireFieldsForReg(touristData);

		nameParts ~= touristData.familyName.value;
		nameParts ~= touristData.givenName.value;

		// Отчество не обязательно, т.к. у некоторых человеков его нет
		if( touristData.patronymic.isSet ) {
			nameParts ~= touristData.patronymic.value;
		}
		userEmail = touristData.email.value;
	}

	RegUserResult regUserRes;
	{
		auto trans = getAuthDB().makeTransaction();
		scope(failure) trans.rollback();
		scope(success) trans.commit();
		regUserRes = registerUser!(getAuthDB)(
			userData.login,
			userData.password,
			nameParts.join(` `), // Склеиваем полное имя пользователя из частей
			userEmail);

		addUserRoles!(getAuthDB)(regUserRes.userNum, [NEW_USER_ROLE]);
	}

	authByPassword(ctx, userData.login, userData.password);
	enforce(ctx.user.isAuthenticated, `Не удалось создать временную сессию для регистрации пользователя!`);

	size_t touristNum;
	if( touristData.num.isSet ) {
		// Используется существующая запись туриста, которую не редактируем в ходе регистрации
		touristNum = touristData.num.value;
	} else {
		// Нужно создать новую запись туриста под этого пользователя
		touristNum = editTourist(ctx, touristData).touristNum;
	}

	// Отправим письмо на подтверждение электронной почты
	sendConfirmEmail(userEmail, regUserRes.confirmUUID);

	return typeof(return)(touristNum, regUserRes.userNum);
}

Tuple!(
	size_t, `userNum`
)
confirmEmail(string confirmUUID)
{
	import std.conv: text;
	static immutable confirmRecFormat = RecordFormat!(
		PrimaryKey!(size_t, "num"),
		bool, "expired",
		bool, "already_confirmed"
	)();
	auto confirm_rs = getAuthDB().queryParams(
`with reg_user as(
	select
		num,
		current_timestamp at time zone 'UTC' > (reg_timestamp + ($1 || ' days')::interval) "expired",
		su.is_email_confirmed "already_confirmed"
	from site_user su
	where su.email_confirm_uuid = $2::uuid
),
upd_res as(
	update site_user as su
		set is_email_confirmed = true
	from reg_user
	where su.num = reg_user.num
		and reg_user.expired is not true
		and reg_user.already_confirmed is not true
	returning reg_user.num, reg_user.expired, reg_user.already_confirmed
)
select * from upd_res
union all
select * from reg_user
where
	reg_user.expired
	or reg_user.already_confirmed`,
	emailConfirmDaysLimit, confirmUUID
	).getRecordSet(confirmRecFormat);

	if( confirm_rs.length == 0 ) {
		throw new Exception(`Не удалось обнаружить пользователя по коду подтверждения.`);
	} else if( confirm_rs.length != 1 ) {
		import std.algorithm: map;
		import std.array: join;
		string multipleNums = confirm_rs[].map!( (rec) => rec.get!"num"().text ).join(", ");
		throw new Exception(`Найдено несколько записей по коду подтверждения: ` ~ multipleNums);
	}

	auto confirm_rec = confirm_rs.front;

	if ( confirm_rec.get!"already_confirmed"(false) ) {
		throw new Exception(`Подверждение электронной почты уже было выполнено`);
	} else if( confirm_rec.get!"expired"(false) ) {
		throw new Exception(`Срок действия кода подтверждения истек. Необходимо повторить регистрацию...`);
	}
	return typeof(return)(confirm_rec.get!`num`());
}

private __gshared string _senderAddress;
private __gshared string _senderEmail;
private __gshared string _senderLogin;
private __gshared string _senderPassword;

shared static this()
{
	import std.file: exists, read, isFile;
	import std.path: expandTilde, buildNormalizedPath;
	import std.json: JSONValue, parseJSON, JSONType;
	string emailSenderConfigPath = expandTilde(`~/sites/mkk/email_sender_config.json`);
	enforce(exists(emailSenderConfigPath) && isFile(emailSenderConfigPath), `Expected email sender config file!`);

	string strConfig = cast(string) read(emailSenderConfigPath);
	JSONValue jConfig = parseJSON(strConfig);
	enforce(jConfig.type == JSONType.object, `Expected object as root of email sender config`);
	auto jAddress = `address` in jConfig;
	if( jAddress && jAddress.type == JSONType.string ) {
		_senderAddress = jAddress.str;
	}
	auto jEmail = `email` in jConfig;
	if( jEmail && jEmail.type == JSONType.string ) {
		_senderEmail = jEmail.str;
	}
	auto jLogin = `login` in jConfig;
	if( jLogin && jLogin.type == JSONType.string ) {
		_senderLogin = jLogin.str;
	}
	auto jPassword = `password` in jConfig;
	if( jPassword && jPassword.type == JSONType.string ) {
		_senderPassword = jPassword.str;
	}
}


import std.uuid: UUID;
void sendConfirmEmail(string userEmail, UUID confirmUUID)
{
	import webtank.net.utils: HTMLEscapeValue;
	import std.net.curl: SMTP;

	import std.conv: text;
	import std.array: join;
	import webtank.security.auth.core.register_user: checkEmailAddress;

	checkEmailAddress(userEmail);

	// Send an email with SMTPS
	auto smtp = SMTP(_senderAddress);
	smtp.setAuthentication(_senderLogin, _senderPassword);
	smtp.mailFrom = _senderEmail;
	smtp.mailTo = [userEmail];

	string[] headers = [
		`To: ` ~ userEmail,
		`From: ` ~ _senderEmail,
		`Subject: Подтверждение регистрации на сайте yar-mkk.ru`,
		`Content-Type: text/html; charset=UTF-8`
	];

	// В отладке отправим на локальный хост. В релизе на рабочий
	debug static immutable string site_addr = `http://localhost`;
	else static immutable string site_addr = `//yar-mkk.ru`;

	string realMsg =
`<div>
	<h3>Подтверждение регистрации на сайте yar-mkk.ru</h3>
	<div>
		Совершена попытка регистрации пользователя сайта <a href="https://yar-mkk.ru">yar-mkk.ru</a>,
		используя данный адрес эл. почты: ` ~ HTMLEscapeValue(userEmail) ~ `.
		Если вы регистрировались на сайте, пройдите по ссылке ниже для продолжения регистрации.
	<div>
	<a href="` ~ site_addr ~ `/dyn/user/reg/email_confirm?confirmUUID=` ~ HTMLEscapeValue(confirmUUID.toString()) ~ `"
		>Подтвердить адрес эл. почты</a>
	<div>Если же вы не совершали этих действий, то просто проигнорируйте сообщение.</div>
	<div>
		Данное сообщение сформировано автоматически.
		Просим вас отвечать на него только в случае вопросов или проблем с регистрацией.
	</div>
</div>`;
	headers ~= `Content-Length: ` ~ realMsg.text;
	smtp.message = headers.join("\r\n") ~ "\r\n\r\n" ~ realMsg;
	smtp.verifyHost = false;
	smtp.verifyPeer = false;
	smtp.perform();
}

// Подтверждение регистрации пользователя. Наделяет его доп. правами по сравнению с пользователем только подавшим заявку
void confirmReg(HTTPContext ctx, Optional!size_t userNum)
{
	import std.format: format;
	enforce(ctx.user.isInRole(`admin`), `Для подтверждения регистрации пользователя вы должны быть администратором`);
	enforce(userNum.isSet, `Ожидался идентификатор пользователя`);

	bool alreadyConfirmed = getAuthDB().queryParams(
		_checkConfirmedQueryFmt.format(
			`su.num`
		), userNum, NEW_USER_ROLE
	).getScalar!bool();
	enforce(!alreadyConfirmed, `Регистрация пользователя уже подтверждена`);

	addUserRoles!(getAuthDB)(userNum, [USER_ROLE]);
}

// Блокировка пользователя. Пользователь не сможет выполнять действия, требующие доп. прав
void lockUser(HTTPContext ctx, Optional!size_t userNum)
{
	enforce(ctx.user.isInRole(`admin`), `Для блокировки пользователя вы должны быть администратором`);
	enforce(userNum.isSet, `Ожидался идентификатор пользователя`);
	// Ставим флаг заблокированности пользователя
	getAuthDB().queryParams(
`update site_user as su
set is_blocked = true
where su.num = $1
`, userNum);

	// На всякий случай сессии тоже удаляем
	getAuthDB().queryParams(
`delete from session as sess
where sess.site_user_num = $1
`, userNum);
}

// Разблокировка пользователя. После разблокировки потребуется повторная аутентификация
void unlockUser(HTTPContext ctx, Optional!size_t userNum)
{
	enforce(ctx.user.isInRole(`admin`), `Для блокировки пользователя вы должны быть администратором`);
	enforce(userNum.isSet, `Ожидался идентификатор пользователя`);
	// Ставим флаг заблокированности пользователя
	getAuthDB().queryParams(
`update site_user as su
set is_blocked = false
where su.num = $1
`, userNum);
}