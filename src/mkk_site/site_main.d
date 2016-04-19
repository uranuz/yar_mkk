module mkk_site.site_main;

import std.getopt: getopt;
import webtank.net.web_server: WebServer;
import mkk_site.routing: Router;

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	ushort port = 8082;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );

	auto server = new WebServer(port, Router);
	server.start();
} 