module mkk_site.main_service.main;

import webtank.net.web_server: WebServer2;

import mkk_site.main_service.service: Service;

// Подключение разделов сервиса
import mkk_site.main_service.auth;
import mkk_site.main_service.moder;
import mkk_site.main_service.pohod;

void main(string[] progAgs)
{
	import std.getopt: getopt;

	ushort port = 8083;
	getopt( progAgs, "port", &port );

	auto server = new WebServer2(port, Service.rootRouter, Service.loger, 5);
	server.start();
}
