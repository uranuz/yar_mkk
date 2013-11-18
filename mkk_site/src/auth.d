module mkk_site.auth;

import std.process, std.conv;

import webtank.net.http.routing, webtank.net.http.context/+, webtank.net.access_control+/;

import mkk_site.site_data, mkk_site.authentication;

immutable thisPagePath = dynamicPath ~ "auth";

shared static this()
{	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;

	auto ticketManager = new MKK_SiteAccessTicketManager( authDBConnStr, eventLogFileName );
	
	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in rq.postVars) && ("user_password" in rq.postVars) )
	{	import webtank.common.conv;
		
		auto newTicket = ticketManager.authenticate(rq.postVars["user_login"], rq.postVars["user_password"]);
		string sidStr;
		if( newTicket.isAuthenticated )
		{	sidStr = webtank.common.conv.toHexString( newTicket.sessionId ) ;
			//TODO: Подумать, что делать с этими багами
			
			rp.cookie[SIDCookieName] = sidStr;
			rp.cookie["user_login"] = rq.postVars["user_login"];

			//Добавляем перенаправление на другую страницу
			string redirectTo = rq.queryVars.get("redirectTo", "");
			rp.redirect(redirectTo);
		}
		else
		{	rp.write("Вход завершился с ошибкой");
		}
	}
	else //Если не пришёл логин с паролем, то работаем в обычном режиме
	{	
		string login = rq.cookie.get("user_login", "");
		rp.write(
//HTML
`<html><body>
<h2>Аутентификация</h2>`);
		if( context.accessTicket.isAuthenticated )
			rp.write("Вход на сайт уже выполен");
		rp.write(
`<hr>
<form method="post" action="#"><table>
  <tr>
    <th>Логин</th> <td><input name="user_login" type="text" value="` ~ login ~ `"></td> 
    <td rowspan="2"><input value="     Войти     " type="submit"></td>
  </tr>
  <tr><th>Пароль</th> <td><input name="user_password" type="password"></td></tr>
</table>`
//`<input type="hidden" name="returnTo" value="` ~ rq.postVars ~ `"
`</form> <br>`
//HTML
		);
		
	}
	
	//rp.write( input );
	rp.write(`</body></html>`);
}

