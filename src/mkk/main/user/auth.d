module mkk.main.user.auth;

import mkk.main.devkit;

import mkk.main.service;
import webtank.security.auth.common.user_identity: CoreUserIdentity;
import webtank.ivy.main_service: MainServiceContext;

shared static this()
{
	MainService.JSON_RPCRouter
		.join!(baseUserInfo)(`auth.baseUserInfo`)
		.join!(authByPassword)(`auth.authByPassword`)
		.join!(logout)(`auth.logout`);

	MainService.pageRouter.joinWebFormAPI!(authHandler)("/api/auth");
}

//import mkk.security.core.access_control;
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

string authByPassword(MainServiceContext ctx, string login, string password)
{
	import webtank.security.auth.core.by_password: authenticateByPassword;
	
	authenticateByPassword(ctx, login, password);
	return ctx.response.cookies.get(CookieName.SessionId);
}

void logout(MainServiceContext ctx) {
	ctx.service.accessController.logout(ctx.user);
}

import std.typecons: Tuple;

Tuple!(
	string, `userLogin`,
	bool, `isAuthFailed`,
	bool, `isAuthenticated`
)
authHandler(MainServiceContext ctx, string userLogin = null, string userPassword = null, string redirectTo = null)
{
	import std.range: empty;

	auto resp = ctx.response;

	/+
	if( "logout" in req.queryForm )
	{
		logout(ctx); // Делаем "разаутентификацию"

		// Если есть куда перенаправлять - перенаправляем...
		/*
		if( redirectTo.length > 0 ) {
			resp.redirect(redirectTo);
		} else {
			resp.redirect(ctx.service.virtualPaths.get(`siteAuthPage`, null));
		}
		*/
		return typeof(return)();
	}
	+/

	bool isAuthFailed = false;

	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( !userLogin.empty && !userPassword.empty )
	{
		string sid = authByPassword(ctx, userLogin, userPassword);

		if( sid.empty )
		{
			isAuthFailed = true;
		}
		else
		{
			// Если есть куда перенаправлять - перенаправляем...
			/*
			if( redirectTo.length > 0 ) {
				resp.redirect(redirectTo);
			} else {
				resp.redirect(ctx.service.virtualPaths.get(`siteAuthPage`, null));
			}
			*/
		}
	}

	return typeof(return)(
		userLogin,
		isAuthFailed,
		(!isAuthFailed && ( ctx.user.isAuthenticated || CookieName.SessionId in resp.cookies ))
	);
}