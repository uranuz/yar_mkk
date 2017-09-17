module mkk_site.view_service.main;

import webtank.net.web_server: WebServer2;

import mkk_site.view_service.service;

// Подключение разделов сервиса
import mkk_site.view_service.index;
import mkk_site.view_service.moder;
import mkk_site.view_service.auth;
import mkk_site.view_service.pohod;
import mkk_site.view_service.pohod_read;
import mkk_site.view_service.pohod_edit;
import mkk_site.view_service.document;
import mkk_site.view_service.tourist_list;
import mkk_site.view_service.tourist_edit;
import mkk_site.view_service.experience;
import mkk_site.view_service.user_settings;
import mkk_site.view_service.stat;

void main(string[] progAgs)
{
	import std.getopt: getopt;

	ushort port = 8082;
	getopt( progAgs, "port", &port );

	auto server = new WebServer2(port, Service.rootRouter, Service.loger, 5);
	server.start();
}
