module webtank.routing_test;

import webtank.net.http.handler, webtank.net.http.context, webtank.net.http.json_rpc_handler, webtank.net.web_server, webtank.net.access_control, webtank.net.http.uri_pattern;

import mkk_site.authentication, mkk_site.site_data;

import std.stdio, std.getopt;

__gshared HTTPRouter router;
__gshared URIPageRouter pageRouter;
__gshared JSON_RPC_Router jsonRPCRouter;

shared static this()
{	router = new HTTPRouter;
	pageRouter = new URIPageRouter( new PlainURIPattern( "/dyn/{remainder}", null, null) );
	jsonRPCRouter = new JSON_RPC_Router( new PlainURIPattern( "/jsonrpc/{remainder}", null, null) );
	
	router
		.join(pageRouter)
		.join(jsonRPCRouter);
	
	jsonRPCRouter.join!(rpcFunc);
	pageRouter.join!(netMain)("/dyn/vasya");
}

string rpcFunc(HTTPContext context, string[string] assocList, int shit)
{	writeln( "context is null: ", context is null );
	writeln( "context.accessTicket is null: ", context.accessTicket is null );
	writeln( "context.accessTicket.user is null: ", context.accessTicket.user is null );
	writeln("user.login: ", context.accessTicket.user.login);
	writeln("Hello, router!!!");
	return "Your kesha is " ~ assocList.get("kesha", null);
	
}

void netMain(HTTPContext context)
{	context.response ~= "Hello, World, again!!!";
	
	
}


void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	ushort port = 8082;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );

	
	auto server = new WebServer(port, router);
	server.start();
}