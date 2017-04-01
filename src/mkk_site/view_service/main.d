module mkk_site.view_service.main;

import webtank.net.web_server: WebServer2;

import mkk_site.view_service.service;

import mkk_site.view_service.index;
import mkk_site.view_service.moder;
import mkk_site.view_service.auth;
import mkk_site.view_service.controls_test;
import mkk_site.view_service.pohod;

void main(string[] progAgs)
{
	import std.getopt: getopt;

	ushort port = 8082;
	getopt( progAgs, "port", &port );

	auto server = new WebServer2(port, Service.rootRouter, Service.loger, 5);
	server.start();
}
