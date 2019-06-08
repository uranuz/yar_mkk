module mkk.main.user.registration;

import mkk.main.devkit;

import mkk.history.client;
import mkk.history.common;

import mkk.main.tourist.model;
import mkk.main.tourist.edit: editTourist;

import mkk.security.core.register_user: registerUser, addUserRoles, RegUserResult;
import mkk.security.core.access_control: emailConfirmDaysLimit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(regUser)(`user.register`);
	MainService.JSON_RPCRouter.join!(confirmEmail)(`user.confirmEmail`);

	MainService.pageRouter.joinWebFormAPI!(regUser)("/api/user/reg/result");
	MainService.pageRouter.joinWebFormAPI!(confirmEmail)("/api/user/reg/email_confirm");
}

struct UserRegData
{
	string login;
	string password;
}

Tuple!(
	size_t, `touristNum`,
	size_t, `userNum`
)
regUser(HTTPContext ctx, TouristDataToWrite touristData, UserRegData userData)
{
	import webtank.db.transaction: makeTransaction;
	import std.exception: enforce;
	import std.array: join;
	import std.range: empty;

	static immutable touristRegRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "num",
		string, "familyName",
		string, "givenName",
		string, "patronymic",
		string, "email"
	)();

	string[] nameParts; // СОбираем сюда полное имя пользователя
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
		touristData.num).getRecord(touristRegRecFormat);
		enforce(touristDBRec !is null, `Не удалось прочитать информацию о туристе из БД`);

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
		if( touristData.familyName.isSet ) {
			nameParts ~= touristData.familyName.value;
		}
		if( touristData.givenName.isSet ) {
			nameParts ~= touristData.givenName.value;
		}
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

		addUserRoles!(getAuthDB)(regUserRes.userNum, [`new_user`]);
	}

	/**
	scope(exit)
	{
		// Убираем права и блокируем пользователя до подтверждения регистрации
		// при выходе из области успешно или с ошибкой
		getAuthDB().queryParams(`with
		bbb(status) as(
			update site_user as su set is_blocked = true
			where su.num = $1
			returning 'blocked'
		),
		rrr(status) as(
			delete from user_access_role uar
			where uar.user_num = $1
			returning 'no_rights'
		)
		select status from bbb
		union all
		select status from rrr`, regUserRes.userNum);
	}
	*/

	MainService.accessController.authenticateByPassword(ctx, userData.login, userData.password);
	enforce(ctx.user.isAuthenticated, `Не удалось создать временную сессию для регистрации пользователя!`);

	size_t touristNum;
	if( !touristData.num.isSet ) {
		// Нужно создать новую запись туриста под этого пользователя
		touristNum = editTourist(ctx, touristData).touristNum;
	} else {
		// Если запись туриста есть, то вызывать ее редактирование нельзя, иначе кто угодно сможет редактировать...
		touristNum = touristData.num.value;
	}

	// Отправим письмо на подтверждение электронной почты
	sendConfirmEmail(userEmail, regUserRes.confirmUUID);

	return typeof(return)(touristNum, regUserRes.userNum);
}

Tuple!(
	size_t, `userNum`
)
confirmEmail(HTTPContext ctx, string confirmUUID)
{
	import std.conv: text;
	static immutable confirmRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "num",
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
	import std.json: JSONValue, parseJSON, JSON_TYPE;
	import std.exception: enforce;
	string emailSenderConfigPath = expandTilde(`~/sites/mkk_site/email_sender_config.json`);
	enforce(exists(emailSenderConfigPath) && isFile(emailSenderConfigPath), `Expected email sender config file!`);

	string strConfig = cast(string) read(emailSenderConfigPath);
	JSONValue jConfig = parseJSON(strConfig);
	enforce(jConfig.type == JSON_TYPE.OBJECT, `Expected object as root of email sender config`);
	auto jAddress = `address` in jConfig;
	if( jAddress && jAddress.type == JSON_TYPE.STRING ) {
		_senderAddress = jAddress.str;
	}
	auto jEmail = `email` in jConfig;
	if( jEmail && jEmail.type == JSON_TYPE.STRING ) {
		_senderEmail = jEmail.str;
	}
	auto jLogin = `login` in jConfig;
	if( jLogin && jLogin.type == JSON_TYPE.STRING ) {
		_senderLogin = jLogin.str;
	}
	auto jPassword = `password` in jConfig;
	if( jPassword && jPassword.type == JSON_TYPE.STRING ) {
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
	import mkk.security.core.register_user: checkEmailAddress;

	checkEmailAddress(userEmail);

	// Send an email with SMTPS
	auto smtp = SMTP(_senderAddress);
	smtp.setAuthentication(_senderLogin, _senderPassword);
	smtp.mailFrom = _senderEmail;
	smtp.mailTo = ["neuranuz@gmail.com"];

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