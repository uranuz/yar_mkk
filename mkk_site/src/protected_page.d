module protected_page;

import webtank.net.application;

webtank.net.application.Application netApp; //Обявление глобального объекта приложения

void netMain(Application netApp)  //Определение главной функции приложения
{	netApp.name = `Тестовое приложение`;
	auto rp = netApp.response;
	auto rq = netApp.request;
	string aaa = "vasya";
	char b = aaa[50];
	if( netApp.auth.isLoggedIn )
	{	rp.write("Добро пожаловать!!!");
	}
	else {
		rp.redirect("/cgi-bin/mkk_site/auth?returnTo=/cgi-bin/mkk_site/protected_page");
		
	}
}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
}
