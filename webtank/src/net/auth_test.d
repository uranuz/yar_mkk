module webtank.auth_test;

import std.stdio;
import std.process;
import std.conv;

import webtank.core.web_application;
import webtank.core.auth;
//import webtank.core.cookies;

WebApplication webApp; //Обявление глобального объекта приложения

void webMain(WebApplication webApp)  //Определение главной функции приложения
{
	try {
	auto auth = new Auth;
	webApp.name = `Тестовое приложение`;
	auto rp = webApp.response;
	auto rq = webApp.request;
	
	auth.authUser(`petechkinv`, `pet12345`);
	auth.getUserInfo
	}
	catch(Exception e)
	{	webApp.response.write(typeid(e).to!string);
		
	}
	//auth.getUser
	//rp.write(webApp.name ~ "\r\n");
	//rp.write("<hr>");
	//rp.write(userInfo.login ~ ` `);
	//rp.write(userInfo.group ~ ` `);
	//rp.write(userInfo.name ~ ` `);
}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	webApp = new WebApplication(&webMain); 
	webApp.run(); //Запускаем приложение
	webApp.finalize(); //Завершаем приложение
	return 0;
}