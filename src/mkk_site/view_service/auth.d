module mkk_site.view_service.auth;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderAuth)("/dyn/auth");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderAuth(HTTPContext context)
{
	import std.json;

	auto req = context.request;
	auto resp = context.response;
	
	// Адрес страницы для перенаправления после аутентификации
	string redirectTo = req.queryForm.get("redirectTo", null);

	if( "logout" in req.queryForm )
	{
		mainServiceCall(`auth.logout`, context); // Делаем "разаутентификацию"

		// Если есть куда перенаправлять - перенаправляем...
		if( redirectTo.length > 0 ) {
			resp.redirect(redirectTo);
		} else {
			resp.redirect(Service.virtualPaths.get(`siteAuthPage`, null));
		}
		return `Перенаправление...`;
	}

	bool isAuthFailed = false;

	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in req.bodyForm) && ("user_password" in req.bodyForm) )
	{
		JSONValue jParams;
		jParams[`login`] = req.bodyForm["user_login"];
		jParams[`password`] = req.bodyForm["user_password"];

		JSONValue jResult;
		try {
			jResult = mainServiceCall!(JSONValue)(`auth.authByPassword`, context, jParams);
		} catch(Exception) {}

		if( jResult.type == JSON_TYPE.STRING )
		{
			resp.cookies["__sid__"] = jResult.str;
			resp.cookies["user_login"] = req.bodyForm["user_login"];
			resp.cookies["__sid__"].path = "/";
			resp.cookies["user_login"].path = "/";

			// Если есть куда перенаправлять - перенаправляем...
			if( redirectTo.length > 0 ) {
				resp.redirect(redirectTo);
			} else {
				resp.redirect(Service.virtualPaths.get(`siteAuthPage`, null));
			}
			return `Перенаправление...`;
		}
		else
		{
			isAuthFailed = true;
		}
	}

	debug import std.stdio;
	debug writeln(`renderAuth, context.user.isAuthenticated: `, context.user.isAuthenticated);

	TDataNode dataDict;
	dataDict[`userLogin`] = req.cookies.get(`user_login`, null);
	dataDict[`isAuthFailed`] = isAuthFailed;
	dataDict[`isAuthenticated`] = !isAuthFailed && ( context.user.isAuthenticated || "__sid__" in resp.cookies );

	return Service.templateCache.getByModuleName("mkk.auth").run(dataDict).str;
}