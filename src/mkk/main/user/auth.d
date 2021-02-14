module mkk.main.user.auth;

import mkk.main.devkit;

import mkk.main.service;

import webtank.security.auth.core.by_password: authByPassword;
import webtank.ivy.service.main: MainServiceContext;

shared static this()
{
	MainService.JSON_RPCRouter
		.join!(baseUserInfo)(`auth.baseUserInfo`)
		.join!(authByPassword)(`auth.authByPassword`)
		.join!(logout)(`auth.logout`);

	MainService.pageRouter.joinWebFormAPI!(authByPassword)("/api/auth");
	MainService.pageRouter.joinWebFormAPI!(logout)("/api/logout");
}

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
baseUserInfo(HTTPContext ctx)
{
	import webtank.security.auth.common.anonymous_user: AnonymousUser;

	import std.json: JSONValue;
	import std.conv: to, ConvException;
	import std.exception: ifThrown;

	ctx.user = ifThrown(ctx.service.accessController.authenticate(ctx.request), null);
	if( ctx.user is null ) {
		ctx.user = new AnonymousUser;
	}

	typeof(return) res;
	res.login = ctx.user.id;
	res.name = ctx.user.name;
	res.userNum = ifThrown!ConvException(
		Optional!size_t(ctx.user.data.get(`userNum`, null).to!size_t), Optional!size_t());
	res.accessRoles = ctx.user.data.get(`accessRoles`, null);
	// TODO: Добавить получение идентификатора туриста для пользователя

	return res;
}

void logout(MainServiceContext ctx, string redirectTo = null)
{
	import webtank.net.http.headers.consts: HTTPHeader;
	import webtank.net.uri: URI;

	ctx.service.accessController.logout(ctx.user);
}
