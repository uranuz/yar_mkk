module mkk_site.auth;

import std.process, std.conv;

import webtank.net.application;

import mkk_site.site_data, mkk_site.authentication;

static this()
{	Application.setHandler(&netMain, dynamicPath ~ "auth");
	Application.setHandler(&netMain, dynamicPath ~ "auth/");
}

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );
	
	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in rq.postVars) && ("user_password" in rq.postVars) )
	{	import webtank.common.conv;
		
		auth.authenticate(rq.postVars["user_login"], rq.postVars["user_password"]);
		string sidStr;
		if( auth.isIdentified() )
		{	sidStr = webtank.common.conv.toHexString( auth.sessionId ) ;
			//TODO: Подумать, что делать с этими багами
			import std.file;
			std.file.append( eventLogFileName, 
				"--------------------\r\n"
				"mkk_site.auth\r\n"
				"auth.isIdentified(): sid: " ~ sidStr ~ ";"
				~ "\r\n"
			);
			
			rp.cookie["sid"] = sidStr;
			rp.cookie["user_login"] = rq.postVars["user_login"];
		}
		
		try { //Логирование запросов к БД для отладки
			import std.file;
			std.file.append( eventLogFileName, 
				"--------------------\r\n"
				"mkk_site.auth\r\n"
				"returnTo: " ~ rq.queryVars.get("returnTo", "") 
				~ " sid: " ~ sidStr ~ ";"
				~ "\r\n"
				~ rp.cookie.getString()
				~ "\r\n"
			);
		} catch(Exception) {}
		
		if( auth.isIdentified() ) 
		{	//rp.write("Вход выполнен успешно"); //Создан Ид сессии для пользователя
			//Добавляем перенаправление на другую страницу
			string returnTo = rq.queryVars.get("returnTo", "");
			rp.redirect(returnTo);
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
		if( auth.isIdentified() )
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

