module mkk_site.auth;

import std.process;
import std.conv;

import webtank.net.application;

enum string dbLibLogFile = `/home/test_serv/sites/test/logs/webtank.log`;

Application netApp; //Обявление глобального объекта приложения

void netMain(Application netApp)  //Определение главной функции приложения
{	
	netApp.name = `Тестовое приложение`;
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	//Если пришёл логин и пароль, то значит выполняем аутентификацию
	if( ("user_login" in rq.postVars) && ("user_password" in rq.postVars) )
	{	import std.digest.digest;
		import webtank.net.authentication: Auth =  Authentication;
		auto sid = netApp.auth.enterUser(rq.postVars["user_login"], rq.postVars["user_password"]);
		string sidStr;
		if( sid != Auth.SessionIdType.init )
		{	//Костыли для правильного преобразования из char[32] в string
			auto sidStrStatic = std.digest.digest.toHexString( sid ) ;
			//TODO: Подумать, что делать с этими багами
			foreach( s; sidStrStatic ) sidStr ~= s;
			rp.cookies["sid"] = sidStr;
			rp.cookies["user_login"] = rq.postVars["user_login"];
		}
		
		try { //Логирование запросов к БД для отладки
			import std.file;
			std.file.append( dbLibLogFile, 
				"--------------------\r\n"
				"mkk_site.auth\r\n"
				"returnTo: " ~ rq.queryVars.get("returnTo", "") 
				~ " sid: " ~ sidStr ~ ";"
				~ "\r\n"
				~ rp.cookies.getResponseStr()
				~ "\r\n"
			);
		} catch(Exception) {}
		
		if( sid != Auth.SessionIdType.init ) 
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
		string login = ( rq.cookies.hasName("user_login") ) ? rq.cookies["user_login"] : "";
		rp.write(
//HTML
`<html><body>
<h2>Аутентификация</h2>`);
		if( netApp.auth.isLoggedIn )
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


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
} 
