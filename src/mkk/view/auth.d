module mkk.view.auth;

import mkk.view.service;
import mkk.view.utils;

shared static this() {
	ViewService.pageRouter.join!(renderAuth)("/dyn/auth");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

import ivy.interpreter.data_node: IvyData;
@IvyModuleAttr(`mkk.Auth`)
IvyData renderAuth(HTTPContext ctx)
{
	import std.json;

	auto req = ctx.request;
	auto resp = ctx.response;

	// Адрес страницы для перенаправления после аутентификации
	string redirectTo = req.queryForm.get("redirectTo", null);

	if( "logout" in req.queryForm )
	{
		ctx.mainServiceCall(`auth.logout`); // Делаем "разаутентификацию"

		// Если есть куда перенаправлять - перенаправляем...
		if( redirectTo.length > 0 ) {
			resp.redirect(redirectTo);
		} else {
			resp.redirect(Service.virtualPaths.get(`siteAuthPage`, null));
		}
		return IvyData();
	}

	bool isAuthFailed = false;

	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("userLogin" in req.bodyForm) && ("userPassword" in req.bodyForm) )
	{
		JSONValue jResult;
		try {
			jResult = ctx.mainServiceCall!(JSONValue)(`auth.authByPassword`, [
				`login`: req.bodyForm["userLogin"],
				`password`: req.bodyForm["userPassword"]
			]);
		} catch(Exception) {}

		if( jResult.type == JSON_TYPE.STRING )
		{
			resp.cookies["__sid__"] = jResult.str;
			resp.cookies["user_login"] = req.bodyForm["userLogin"];
			resp.cookies["__sid__"].path = "/";
			resp.cookies["user_login"].path = "/";

			// Если есть куда перенаправлять - перенаправляем...
			if( redirectTo.length > 0 ) {
				resp.redirect(redirectTo);
			} else {
				resp.redirect(Service.virtualPaths.get(`siteAuthPage`, null));
			}
			return IvyData();
		}
		else
		{
			isAuthFailed = true;
		}
	}

	return IvyData([
		`userLogin`: IvyData(req.cookies.get(`user_login`, null)),
		`isAuthFailed`: IvyData(isAuthFailed),
		`isAuthenticated`: IvyData(!isAuthFailed && ( ctx.user.isAuthenticated || "__sid__" in resp.cookies ))
	]);
}