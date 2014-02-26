module mkk_site.site_main;

import std.conv, std.getopt;

import webtank.net.web_server, webtank.net.http.handler, webtank.net.http.json_rpc_handler, webtank.net.http.context, webtank.net.http.http;

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
		
	Router.onError.join( (Throwable error, HTTPContext context) {
		context.response ~= "<http><body><h2>500 Внутренняя ошибка сервера!!!</h2>\r\n"
		~ error.to!string ~ "</body></http>";
		return true;
	} );

	PageRouter.onError.join( (HTTPException error, HTTPContext context) {
		context.response ~= "<http><body><h2>" ~ error.HTTPStatusCode.to!string ~ " Какое-то HTTP ошибко!!!</h2>\r\n"
		~ error.to!string ~ "</body></http>";
		return true;
	} );
	
	auto accessController = new MKK_SiteAccessController;
	
	Router.onPostPoll ~= (HTTPContext context, bool isMatched) {
		context._setuser( accessController.authenticate(context) );
	};
	
	JSONRPCRouter.onError.join( (Throwable error, HTTPContext context) {
		context.response ~= `{"jsonrpc":"2.0","error":{"msg":"`
		~ error.msg ~ `"}}`;
		return true;
	} );
}

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	ushort port = 8082;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );

	
	auto server = new WebServer(port, Router);
	server.start();
} 