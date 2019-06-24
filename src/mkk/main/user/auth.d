module mkk.main.user.auth;

import webtank.net.http.context: HTTPContext;

import mkk.main.service;
import mkk.security.common.exception: SecurityException;

shared static this()
{
	MainService.JSON_RPCRouter
		.join!(baseUserInfo)(`auth.baseUserInfo`)
		.join!(authByPassword)(`auth.authByPassword`)
		.join!(logout)(`auth.logout`);
}

import mkk.security.core.access_control;
import std.typecons: Tuple;
import webtank.common.optional: Optional;

/// Получить базовую информацию о пользователе по идентификатору сессии
Tuple!(
	string, `login`,
	string, `name`,
	Optional!size_t, `userNum`,
	string, `accessRoles`,
	Optional!size_t, `touristNum`
)
baseUserInfo(HTTPContext context)
{
	import std.json: JSONValue;
	import std.conv: to, ConvException;
	auto userIdentity = MainService.accessController.authenticate(context);

	typeof(return) res;
	res.login = userIdentity.id;
	res.name = userIdentity.name;

	if( userIdentity.data.get(`userNum`, null).length > 0 )
	{
		try {
			res.userNum = userIdentity.data[`userNum`].to!size_t;
		} catch(ConvException ex) {}
	}

	res.accessRoles = userIdentity.data.get(`accessRoles`, null);
	// TODO: Добавить получение идентификатора туриста для пользователя

	return res;
}

string authByPassword(HTTPContext context, string login, string password)
{
	import std.exception: enforce;
	auto userIdentity = cast(MKKUserIdentity) MainService.accessController.authenticateByPassword(context, login, password);

	enforce!SecurityException(
		userIdentity && userIdentity.isAuthenticated,
		`Failed to authenticate user by login and password`);

	return context.request.cookies.get(`__sid__`);
}

void logout(HTTPContext context)
{
	MainService.accessController.logout(context.user);
}