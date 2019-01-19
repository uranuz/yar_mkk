module mkk_site.main_service.user.registration;

import mkk_site.main_service.devkit;
import mkk_site.data_model.pohod_edit: PohodDataToWrite, DBName, PohodFileLink;
import webtank.security.right.common: GetSymbolAccessObject;
import mkk_site.history.client;
import mkk_site.history.common;
import mkk_site.data_model.tourist_edit;
import mkk_site.security.core.register_user: registerUser, addUserRoles, RegUserResult;
import mkk_site.security.core.access_control: emailConfirmDaysLimit;

import mkk_site.main_service.tourist.edit: editTourist;


shared static this()
{
	MainService.JSON_RPCRouter.join!(regUser)(`user.register`);
	MainService.JSON_RPCRouter.join!(confirmEmail)(`user.confirmEmail`);

	MainService.pageRouter.joinWebFormAPI!(findTourist)("/api/user/reg/find_tourist");
	MainService.pageRouter.joinWebFormAPI!(emailConfirm)("/api/user/reg/email_confirm");
	MainService.pageRouter.joinWebFormAPI!(userReg)("/api/user/reg/results");
	MainService.pageRouter.joinWebFormAPI!(renderUserReg)("/api/user/reg");
}

import std.json: JSONValue;
JSONValue regUser(HTTPContext ctx, TouristDataToWrite touristData, UserRegData userData)
{
	import webtank.db.transaction: makeTransaction;
	import std.exception: enforce;

	import std.array: join;
	string[] nameParts; // Склеиваем имя пользователя
	if( touristData.familyName.isSet ) {
		nameParts ~= touristData.familyName.value;
	}
	if( touristData.givenName.isSet ) {
		nameParts ~= touristData.givenName.value;
	}
	if( touristData.patronymic.isSet ) {
		nameParts ~= touristData.patronymic.value;
	}

	RegUserResult regUserRes;
	{
		auto trans = getAuthDB().makeTransaction();
		scope(failure) trans.rollback();
		scope(success) trans.commit();
		regUserRes = registerUser!(getAuthDB)(
			userData.login,
			userData.password,
			nameParts.join(` `),
			touristData.email
		);

		addUserRoles!(getAuthDB)(regUserRes.userNum, [`new_user`]);
	}

	scope(exit)
	{
		// Убираем права и блокируем пользователя до подтверждения регистрации
		// при выходе из области успешно или с ошибкой
		getAuthDB().query(`with
		bbb(status) as(
			update site_user as su set is_blocked = true
			where su.num = ` ~ regUserRes.userNum.text ~ `
			returning 'blocked'
		),
		rrr(status) as(
			delete from user_access_role uar
			where uar.user_num = ` ~ regUserRes.userNum.text ~ `
			returning 'no_rights'
		)
		select status from bbb
		union all
		select status from rrr`);
	}

	MainService.accessController.authenticateByPassword(ctx, userData.login, userData.password);
	enforce(ctx.user.isAuthenticated, `Не удалось создать временную сессию для регистрации пользователя!`);

	// Отправим письмо на подтверждение пароля
	sendConfirmEmail(touristData.email, regUserRes.confirmUUID);

	auto jResult = JSONValue([
		"touristNum":  editTourist(ctx, touristData).touristNum,
		"userNum": regUserRes.userNum
	]);

	return jResult;
}

JSONValue confirmEmail(HTTPContext ctx, string confirmUUID)
{
	import std.conv: text;
	static immutable confirmRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "num",
		bool, "expired",
		bool, "already_confirmed"
	)();
	auto confirm_rs = getAuthDB().query(
`with reg_user as(
	select
		num,
		current_timestamp at time zone 'UTC' > (reg_timestamp + interval '` ~ emailConfirmDaysLimit.text ~ ` days') "expired",
		su.is_email_confirmed "already_confirmed"
	from site_user su
	where su.email_confirm_uuid = '` ~ PGEscapeStr(confirmUUID) ~ `'::uuid
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
	or reg_user.already_confirmed`
	).getRecordSet(confirmRecFormat);

	JSONValue res = [`num`: JSONValue()];
	if( confirm_rs.length == 0 ) {
		res[`message`] = `Не удалось обнаружить пользователя по коду подтверждения`;
	} else if( confirm_rs.length == 1 ) {
		auto confirm_rec = confirm_rs.front;
		res[`num`] = confirm_rec.get!`num`();
		if ( confirm_rec.get!"already_confirmed"(false) ) {
			res[`message`] = `Подверждение электронной почты уже было выполнено ранее`;
		} else if( confirm_rec.get!"expired"(false) ) {
			res[`message`] = `Срок действия кода подтверждения истек`;
		} else {
			res[`message`] = `Подтверждение электронной почты успешно выполнено`;
		}
	} else {
		import std.algorithm: map;
		import std.array: join;
		res[`message`] = `Найдено несколько записей по коду подтверждения: ` ~ confirm_rs[].map!(
				(rec) => rec.get!"num"().text
			).join(", ");
	}
	return res;
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

import std.net.curl: SMTP;

import std.conv: text;
import std.array: join;
import std.uuid: UUID;

void sendConfirmEmail(string userEmail, UUID confirmUUID)
{
	import webtank.net.utils: HTMLEscapeValue;

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
	<a href="` ~ site_addr ~ `/dyn/user/reg/email_confirm?uuid=` ~ HTMLEscapeValue(confirmUUID.toString()) ~ `"
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

import mkk_site.data_model.tourist_edit;
JSONValue findTourist(HTTPContext ctx)
{
	auto req = ctx.request;

	return JSONValue();
}

JSONValue userReg(HTTPContext ctx, TouristDataToWrite touristData, UserRegData userData)
{
	import webtank.common.std_json.to: toStdJSON;

	JSONValue writeRes;
	try {
		writeRes = regUser(ctx, touristData, userData).toStdJSON();
		writeRes[`errorMsg`] = JSONValue();
	} catch(Exception ex) {
		writeRes[`errorMsg`] = ex.msg;
	}
	return writeRes;
}

import mkk_site.main_service.tourist.read: readTourist;
JSONValue renderUserReg(HTTPContext ctx, Optional!size_t num)
{
	return JSONValue([
		"tourist": readTourist(ctx, num).tourist.toStdJSON()
	]);
}

JSONValue emailConfirm(HTTPContext ctx, string uuid)
{
	return JSONValue([
		`confirmUUID`: confirmEmail(ctx, uuid)
	]);
}