module webtank.core.main;

import webtank.core.web_application;

import std.process;

WebApplication webApp; //Обявление глобального объекта приложения

void webMain(WebApplication webApp)  //Определение главной функции приложения
{	webApp.name = `Тестовое приложение`;
	auto rp = webApp.response;
	auto rq = webApp.request;
	rp.write(webApp.name ~ "\r\n");
	rp.write( webApp.auth.sessionId );
	rp.write( "\r\n" ~ webApp.auth.userInfo.login );
	rp.write( "\r\n" ~ webApp.auth.userInfo.group );
}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	webApp = new WebApplication(&webMain); 
	webApp.run(); //Запускаем приложение
	webApp.finalize(); //Завершаем приложение
	return 0;
}