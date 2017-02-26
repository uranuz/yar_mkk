module mkk_site.site_main;

import std.getopt: getopt;
import webtank.net.web_server: WebServer, WebServer2;
import mkk_site.routing: Router;
import mkk_site.logging: PrioriteLoger;

import etc.linux.memoryerror;

void main(string[] progAgs)
{
	//Основной поток - поток управления потоками

	registerMemoryErrorHandler();
	scope(exit) deregisterMemoryErrorHandler();

	ushort port = 8082;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );

	auto server = new WebServer2(port, Router, PrioriteLoger, 5);
	server.start();
} 