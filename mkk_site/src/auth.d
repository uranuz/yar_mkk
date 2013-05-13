module webtank.core.main;

import webtank.core.web_application;

import std.process;
import std.conv;

WebApplication webApp; //Обявление глобального объекта приложения

void webMain(WebApplication webApp)  //Определение главной функции приложения
{	try {
	webApp.name = `Тестовое приложение`;
	auto rp = webApp.response;
	auto rq = webApp.request;
	rp.write(
//HTML
`<html><body>
<h2>Аутентификация</h2>
<hr>
<form method="post" action="#"><table>
  <tr>
    <th>Логин</th> <td><input name="user_login" type="text"></td> 
    <td rowspan="2"><input value="     Войти     " type="submit"></td>
  </tr>
  <tr><th>Пароль</th> <td><input name="user_password" type="password"></td></tr>
</table></form>`
//HTML
	);
	string input;
	input ~= rq.POST.length.to!string ~ "   "  ;
	//if( "user_login" in rq.POST ) input ~= rq.POST["user_login"] ~ "   ";
	//if( "user_password" in rq.POST ) input ~= rq.POST["user_password"];
	foreach( key, value; rq.POST)
	{	rp.write("#>> "); rp.write( key ~ " : " ~ value );
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
