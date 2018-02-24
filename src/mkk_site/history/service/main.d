module mkk_site.history.service.main;

import webtank.net.web_server: WebServer2;
import mkk_site.common.service: Service;

// Подключение разделов сервиса
import mkk_site.history.service.writer;

void main(string[] progAgs)
{
	import std.getopt: getopt;

	ushort port = 8084;
	getopt(progAgs, "port", &port);

	auto server = new WebServer2(port, Service.rootRouter, Service.loger, 5);
	server.start();
}
