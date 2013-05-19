module protected_page;

import webtank.core.web_application;

WebApplication webApp; //Обявление глобального объекта приложения

void webMain(WebApplication webApp)  //Определение главной функции приложения
{	webApp.name = `Тестовое приложение`;
	auto rp = webApp.response;
	auto rq = webApp.request;
	string aaa = "vasya";
	char b = aaa[50];
	if( webApp.auth.isLoggedIn )
	{	rp.write("Добро пожаловать!!!");
	}
	else {
		rp.redirect("/cgi-bin/mkk_site/auth?returnTo=/cgi-bin/mkk_site/protected_page");
		
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
