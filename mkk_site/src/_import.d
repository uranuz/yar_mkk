module mkk_site._import;

import webtank.net.web_server; //Подключаем сервер

public import mkk_site.site_data;

import mkk_site.show_tourist, mkk_site.show_pohod, mkk_site.authentication, mkk_site.auth, mkk_site.admin, mkk_site.edit_tourist, mkk_site.edit_pohod;

//Инициализация сайта МКК
shared static this 
{	//Создаём менеждера по выдаче билетов доступа
	auto ticketManager = new MKK_SiteAccessTicketManager(authDBConnStr);
	
	Router
		.join( new HTTPRouterRule(ticketManager) ) //Добавляем базовый HTTP - роутер
		.join( new URIRouterRule )  //Добавляем URI - роутер (маршрутизация по адресам)
		.join( new JSON_RPC_RouterRule );  //Добавляем JSON-RPC - роутер (удалённый вызов процедур)
}