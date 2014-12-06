module mkk_site.auth;

import std.conv, std.base64;

import webtank.net.http.handler, webtank.net.http.context/+, webtank.net.access_control+/;

import mkk_site, mkk_site.access_control;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "auth";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;

	auto accessController = new MKK_SiteAccessController;

	string content = "<h2>Аутентификация</h2><hr>\r\n";
	bool isAuthenticated = false;
	
	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in rq.bodyForm) && ("user_password" in rq.bodyForm) )
	{	auto newIdentity = cast(MKK_SiteUser) accessController.authenticateByPassword(
			rq.bodyForm["user_login"],
			rq.bodyForm["user_password"],
			rq.headers.get("x-real-ip", ""),
			rq.headers.get("user-agent", "")
		);
		string sidStr;
		if( newIdentity !is null && newIdentity.isAuthenticated )
		{	sidStr = Base64URL.encode( newIdentity.sessionId ) ;
			
			rp.cookies["__sid__"] = sidStr;
			rp.cookies["user_login"] = rq.bodyForm["user_login"];
			rp.cookies["__sid__"].path = "/";
			rp.cookies["user_login"].path = "/";

			//Добавляем перенаправление на другую страницу
			string redirectTo = rq.queryForm.get("redirectTo", "");
			
			if( redirectTo.length > 0 )
				rp.redirect(redirectTo);
		}
		else
		{	content ~=
`<b>Не удалось выполнить аутентификацию на сайте.<b>
Проверьте, пожалуйста, правильность ввода учётных данных.
Если ошибка повторяется, свяжитесь с администратором или модератором
системы для решения возникшей проблемы.`;
			return content;
		}
	}

	 //Если не пришёл логин с паролем, то работаем в обычном режиме
	string login = rq.cookies.get("user_login", "");

	if( context.user.isAuthenticated || isAuthenticated )
		content ~= "Вход на сайт уже выполен";
		
	content ~=
`<form method="post" action="#"><table>
  <tr>
    <th>Логин</th> <td><input name="user_login" type="text" value="` ~ login ~ `"></td> 
    <td rowspan="2"><input value="     Войти     " type="submit"></td>
  </tr>
  <tr><th>Пароль</th> <td><input name="user_password" type="password"></td></tr>
</table>`
//`<input type="hidden" name="returnTo" value="` ~ rq.bodyForm ~ `"
`</form> <br>`;

	return content;
}

