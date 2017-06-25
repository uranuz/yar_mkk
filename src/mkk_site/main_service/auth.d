module mkk_site.main_service.auth;

import webtank.net.http.context: HTTPContext;

import mkk_site.main_service.service;

shared static this()
{
	Service.JSON_RPCRouter
		.join!(baseUserInfo)(`auth.baseUserInfo`)
		.join!(authByPassword)(`auth.authByPassword`)
		.join!(logout)(`auth.logout`);
}

import mkk_site.access_control;

/// Получить базовую информацию о пользователе по идентификатору сессии
auto baseUserInfo(HTTPContext context)
{
	import std.json: JSONValue;
	import std.conv: to, ConvException;
	auto userIdentity = Service.accessController.authenticate(context);

	JSONValue result;
	result[`login`] = userIdentity.id;
	result[`name`] = userIdentity.name;

	result[`userNum`] = null;
	if( userIdentity.data.get(`userNum`, null).length > 0 )
	{
		try {
			result[`userNum`] = userIdentity.data[`userNum`].to!size_t;
		} catch(ConvException ex) {}
	}

	result[`group`] = userIdentity.data.get(`group`, null);
	result[`touristNum`] = null; // TODO: Добавить получение идентификатора туриста для пользователя

	return result;
}

string authByPassword(HTTPContext context, string login, string password)
{
	import std.base64: Base64URL;
	
	auto userIdentity = cast(MKKUserIdentity) Service.accessController.authenticateByPassword(
		login,
		password,
		context.request.headers[`x-real-ip`],
		context.request.headers[`user-agent`]
	);

	if( !userIdentity || !userIdentity.isAuthenticated ) {
		throw new AuthException(`Failed to authenticate user by login and password`);
	}

	auto resp = context.response;
	string sidStr = Base64URL.encode(userIdentity.sessionId) ;

	resp.cookies["__sid__"] = sidStr;
	resp.cookies["user_login"] = login;
	resp.cookies["__sid__"].path = "/";
	resp.cookies["user_login"].path = "/";

	return sidStr;
}

void logout(HTTPContext context)
{
	Service.accessController.logout(context.user);
}