module mkk_site.auth;

import std.process, std.conv, std.base64;

import webtank.net.http.handler, webtank.net.http.context/+, webtank.net.access_control+/;

import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, mkk_site._import;

immutable thisPagePath = dynamicPath ~ "auth";

shared static this()
{	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;

	auto accessController = new MKK_SiteAccessController;

	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in rq.postVars) && ("user_password" in rq.postVars) )
	{	auto newIdentity = cast(MKK_SiteUser) accessController.authenticateByPassword(
			rq.postVars["user_login"], 
			rq.postVars["user_password"],
			rq.remoteAddress.toAddrString(),
			rq.headers["user-agent"]
		);
		string sidStr;
		if( newIdentity !is null && newIdentity.isAuthenticated )
		{	sidStr = Base64URL.encode( newIdentity.sessionId ) ;
			//TODO: Подумать, что делать с этими багами
			
			rp.cookie["__sid__"] = sidStr;
			rp.cookie["user_login"] = rq.postVars["user_login"];

			//Добавляем перенаправление на другую страницу
			string redirectTo = rq.queryVars.get("redirectTo", "");
			rp.redirect(redirectTo);
		}
		else
		{	auto tpl = getGeneralTemplate(context);
			string content =
`<h2>Аутентификация</h2>
<hr>
<b>Не удалось выполнить аутентификацию на сайте.<b>
Проверьте, пожалуйста, правильность ввода учётных данных.
Если ошибка повторяется, свяжитесь с администратором или модератором
системы для решения возникшей проблемы.`;
			tpl.set( "content", content );
			rp.write( tpl.getString() );
		}
	}
	else //Если не пришёл логин с паролем, то работаем в обычном режиме
	{	
		string login = rq.cookie.get("user_login", "");
		auto tpl = getGeneralTemplate(context);
		
		string content = `<h2>Аутентификация</h2>`;
		
		if( context.user.isAuthenticated )
			content ~= "Вход на сайт уже выполен";
		
		content ~=
`<hr>
<form method="post" action="#"><table>
  <tr>
    <th>Логин</th> <td><input name="user_login" type="text" value="` ~ login ~ `"></td> 
    <td rowspan="2"><input value="     Войти     " type="submit"></td>
  </tr>
  <tr><th>Пароль</th> <td><input name="user_password" type="password"></td></tr>
</table>`
//`<input type="hidden" name="returnTo" value="` ~ rq.postVars ~ `"
`</form> <br>`;
		
		tpl.set( "content", content );
		rp.write( tpl.getString() );
	}
}

