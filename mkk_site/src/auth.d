module mkk_site.auth;

import std.process, std.conv;

import webtank.net.http.router, webtank.net.http.request, webtank.net.http.response;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

static this()
{	Router.setPathHandler(dynamicPath ~ "auth", &netMain);
}

immutable thisPagePath = dynamicPath ~ "auth";

void netMain(ServerRequest rq, ServerResponse rp)  //Определение главной функции приложения
{	
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );
	
	auto tpl = getGeneralTemplate(thisPagePath);
	
	string content = `<h2>Аутентификация</h2>`;

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
				"redirectTo: " ~ rq.queryVars.get("redirectTo", "") 
				~ " sid: " ~ sidStr ~ ";"
				~ "\r\n"
				~ rp.cookie.getString()
				~ "\r\n"
			);
		} catch(Exception) {}
		
		if( auth.isIdentified() ) 
		{	//rp.write("Вход выполнен успешно"); //Создан Ид сессии для пользователя
			//Добавляем перенаправление на другую страницу
			string redirectTo = rq.queryVars.get("redirectTo", "");
			rp.redirect(redirectTo);
		}
		else
		{	content = `Вход завершился с ошибкой`;
		}
	}
	else //Если не пришёл логин с паролем, то работаем в обычном режиме
	{	
		string login = rq.cookie.get("user_login", "");
		
		if( auth.isIdentified() )
			content ~= `Вход на сайт уже выполен`;
		else
			content ~= `<hr>
<form method="post" action="#">
	<table>
		<tr>
			<th>Логин</th> <td><input name="user_login" type="text" value="` ~ login ~ `"></td> 
			<td rowspan="2"><input value="     Войти     " type="submit"></td>
		</tr>
		<tr><th>Пароль</th> <td><input name="user_password" type="password"></td></tr>
	</table>
</form>`;
		
	}
	tpl.set( "content", content );
	rp.write( tpl.getString() );

}

