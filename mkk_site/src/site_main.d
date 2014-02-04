module mkk_site.site_main;

import std.conv, std.getopt;

import webtank.net.web_server, webtank.net.http.handler, webtank.net.http.json_rpc_handler, webtank.net.http.context;

import mkk_site.site_data, mkk_site.access_control;

__gshared HTTPRouter Router;
__gshared URIPageRouter PageRouter;
__gshared JSON_RPC_Router JSONRPCRouter;

//Инициализация сайта МКК
shared static this()
{	Router = new HTTPRouter;
	PageRouter = new URIPageRouter( dynamicPath ~ "{remainder}" );
	JSONRPCRouter = new JSON_RPC_Router( JSON_RPC_Path ~ "{remainder}" );
	
	Router
		.join(JSONRPCRouter)
		.join(PageRouter);
		
	Router.onError ~= (HTTPContext context, Throwable error) {
		context.response ~= "<http><body><h2>500 Внутренняя ошибка сервера!!!</h2>\r\n" 
		~ error.to!string ~ "</body></http>";
		return true;
	};
	
	auto accessController = new MKK_SiteAccessController;
	
	Router.onPreProcess ~= (HTTPContext context) {
		context._setuser( accessController.authenticate(context) );
	};
	
	JSONRPCRouter.onError ~= (HTTPContext context, Throwable error) {
		context.response ~= `{"jsonrpc":"2.0","error":{"msg":"` 
		~ error.msg ~ `"}}`;
		return true;
	};
}

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	ushort port = 8082;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );

	
	auto server = new WebServer(port, Router);
	server.start();
} 