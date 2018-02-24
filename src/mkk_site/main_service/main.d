module mkk_site.main_service.main;

import webtank.net.web_server: WebServer2;
import mkk_site.common.service: Service;

// Подключение разделов сервиса
import mkk_site.main_service.auth;
import mkk_site.main_service.moder;
import mkk_site.main_service.pohod_list;
import mkk_site.main_service.pohod_read;
import mkk_site.main_service.pohod_filters;
import mkk_site.main_service.pohod_edit;
import mkk_site.main_service.document_list;
import mkk_site.main_service.document_edit;
import mkk_site.main_service.tourist_list;
import mkk_site.main_service.tourist_edit;
import mkk_site.main_service.experience;
import mkk_site.main_service.user_settings;
import mkk_site.main_service.stat;

void main(string[] progAgs)
{
	import std.getopt: getopt;

	ushort port = 8083;
	getopt(progAgs, "port", &port);

	auto server = new WebServer2(port, Service.rootRouter, Service.loger, 5);
	server.start();
}
