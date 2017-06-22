module mkk_site.main_service.main;

import webtank.net.web_server: WebServer2;

import mkk_site.main_service.service: Service;

import std.conv, std.string, std.utf;


// Подключение разделов сервиса
import mkk_site.main_service.auth;
import mkk_site.main_service.moder;
import mkk_site.main_service.pohod;
import mkk_site.main_service.pohod_read;
import mkk_site.main_service.pohod_filters;
import mkk_site.main_service.pohod_edit;
//import mkk_site.main_service.document;
import mkk_site.main_service.tourist_list;
import mkk_site.main_service.experience;

void main(string[] progAgs)
{
	import std.getopt: getopt;

	ushort port = 8083;
	getopt( progAgs, "port", &port );

	auto server = new WebServer2(port, Service.rootRouter, Service.loger, 5);
	server.start();
}
