module webtank.core.main;

import webtank.core.web_application;

import std.process;
import std.conv;

enum string dbLibLogFile = `/home/test_serv/sites/test/logs/webtank.log`;

WebApplication webApp; //Обявление глобального объекта приложения

void webMain(WebApplication webApp)  //Определение главной функции приложения
{	try {
	webApp.name = `Тестовое приложение`;
	auto rp = webApp.response;
	auto rq = webApp.request;
	
	
	if( ("user_login" in rq.POST) && ("user_password" in rq.POST) )
	{	string sid = webApp.auth.enterUser(rq.POST["user_login"], rq.POST["user_password"]);
		rp.cookies["sid"] = sid;
		rp.cookies["user_login"] = rq.POST["user_login"];
		if( sid.length > 0 ) 
		{	//rp.write("Вход выполнен успешно"); //Создан Ид сессии для пользователя
			//Добавляем перенаправление на другую страницу
			try { //Логирование запросов к БД для отладки
				import std.file;
				std.file.append( dbLibLogFile, 
					"--------------------\r\n"
					"mkk_site.auth\r\n"
					"returnTo: " ~ rq.GET.get("returnTo", "") ~ ";"
					~ "\r\n"
				);
			} catch(Exception) {}
			string returnTo = rq.GET.get("returnTo", "");
			rp.redirect(returnTo);
		}
		else
		{	rp.write("Вход завершился с ошибкой");
		}
	}
	else
	{	
		string login = ( rq.cookies.hasName("user_login") ) ? rq.cookies["user_login"] : "";
		rp.write(
//HTML
`<html><body>
<h2>Аутентификация</h2>`);
		if( webApp.auth.sessionId.length > 0 )
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
//`<input type="hidden" name="returnTo" value="` ~ rq.POST ~ `"
`</form> <br>`
//HTML
		);
		
	}
	
	//rp.write( input );
	rp.write(`</body></html>`);
	} catch (Throwable e)
	{	webApp.response.write(typeid(e).to!string);
		
		
	}
}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	webApp = new WebApplication(&webMain); 
	webApp.run(); //Запускаем приложение
	webApp.finalize(); //Завершаем приложение
	return 0;
} 
