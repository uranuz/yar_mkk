module mkk.main.user.auth;

import mkk.main.devkit;

import mkk.main.service;
import webtank.security.auth.common.exception: AuthException;
import webtank.security.auth.common.user_identity: CoreUserIdentity;

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
	auto userIdentity = cast(CoreUserIdentity) MainService.accessController.authenticateByPassword(context, login, password);

	enforce!AuthException(
		userIdentity !is null && userIdentity.isAuthenticated,
		`Failed to authenticate user by login and password`);

	return context.response.cookies.get(`__sid__`);
}

void logout(HTTPContext context)
{
	MainService.accessController.logout(context.user);
}

import std.typecons: Tuple;

Tuple!(
	string, `userLogin`,
	bool, `isAuthFailed`,
	bool, `isAuthenticated`
)
authHandler(HTTPContext ctx, string userLogin = null, string userPassword = null, string redirectTo = null)
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
		string sid;
		//try {
			sid = authByPassword(ctx, userLogin, userPassword);
		//} catch(Exception) {}

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
		(!isAuthFailed && ( ctx.user.isAuthenticated || "__sid__" in resp.cookies ))
	);
}