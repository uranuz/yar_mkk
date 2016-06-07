module mkk_site.auth;

import std.conv, std.base64;

import webtank.net.http.handler, webtank.net.http.context;

import mkk_site.page_devkit;
import mkk_site.access_control;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "auth";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;

	// Адрес страницы для перенаправления после аутентификации
	string redirectTo = rq.queryForm.get("redirectTo", null);

	auto accessController = new MKK_SiteAccessController;

	bool isAuthenticatedNow = false;
	bool isAuthFailed = false;

	auto tpl = getPageTemplate( pageTemplatesDir ~ "page_auth.html" );
	
	if( "logout" in rq.queryForm )
	{
		// Получаем удостоверение пользователя
		auto identity = cast(MKK_SiteUser) context.user;
		
		if( identity )
			identity.logout(); // Делаем "разаутентификацию""

		// Если есть куда перенаправлять - перенаправляем...
		if( redirectTo.length > 0 )
		{
			rp.redirect(redirectTo);
			return `Перенаправление...`;
		}
	}
	
	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in rq.bodyForm) && ("user_password" in rq.bodyForm) )
	{	auto newIdentity = cast(MKK_SiteUser) accessController.authenticateByPassword(
			rq.bodyForm["user_login"],
			rq.bodyForm["user_password"],
			rq.headers.get("x-real-ip", ""),
			rq.headers.get("user-agent", "")
		);
		string sidStr;
		if( newIdentity && newIdentity.isAuthenticated )
		{	sidStr = Base64URL.encode( newIdentity.sessionId ) ;
			
			rp.cookies["__sid__"] = sidStr;
			rp.cookies["user_login"] = rq.bodyForm["user_login"];
			rp.cookies["__sid__"].path = "/";
			rp.cookies["user_login"].path = "/";
			isAuthenticatedNow = true;

			// Если есть куда перенаправлять - перенаправляем...
			if( redirectTo.length > 0 )
			{
				rp.redirect(redirectTo);
				return `Перенаправление...`;
			}
		}
		else
		{
			isAuthFailed = true;
			tpl.setHTMLText( "auth_msg",
`Не удалось выполнить аутентификацию на сайте.
Проверьте, пожалуйста, правильность ввода учётных данных и попробуйте еще раз.
Если ошибка повторяется, свяжитесь с администратором системы для решения возникшей проблемы.`
			);
		}
	}

	tpl.setHTMLText( "user_login", rq.cookies.get("user_login", null) );

	if( !isAuthFailed && ( context.user.isAuthenticated || isAuthenticatedNow ) )
		tpl.setHTMLText( "auth_msg", `Вход на сайт выполнен` );

	return tpl.getString();
}