module mkk_site.auth;

import std.process;
import std.conv;

enum string dbLibLogFile = `/home/test_serv/sites/test/logs/webtank.log`;

webtank.net.Application netApp; //Обявление глобального объекта приложения

void netMain(webtank.net.Application netApp)  //Определение главной функции приложения
{	try {
	netApp.name = `Тестовое приложение`;
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	
	if( ("user_login" in rq.POST) && ("user_password" in rq.POST) )
	{	string sid = netApp.auth.enterUser(rq.POST["user_login"], rq.POST["user_password"]);
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
		if( netApp.auth.sessionId.length > 0 )
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
	{	netApp.response.write(typeid(e).to!string);
		
		
	}
}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new webtank.net.Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
} 
