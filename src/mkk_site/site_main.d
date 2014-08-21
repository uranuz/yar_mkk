module mkk_site.site_main;

import std.conv, std.getopt;

import webtank.net.web_server, webtank.net.http.handler, webtank.net.http.json_rpc_handler,
webtank.net.http.context, webtank.net.http.http;

import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, webtank.common.logger;

__gshared HTTPRouter Router;
__gshared URIPageRouter PageRouter;
__gshared JSON_RPC_Router JSONRPCRouter;
__gshared Logger SiteLogger;
__gshared Logger PrioriteLogger;

//Инициализация сайта МКК
shared static this()
{	
	import std.exception: assumeUnique;
	Router = new HTTPRouter;
	PageRouter = new URIPageRouter( dynamicPath ~ "{remainder}" );
	JSONRPCRouter = new JSON_RPC_Router( JSON_RPC_Path ~ "{remainder}" );
	SiteLogger = new ThreadedLogger( cast(shared) new FileLogger(eventLogFileName, LogLevel.error) );
	PrioriteLogger = new ThreadedLogger( cast(shared) new FileLogger(prioriteLogFileName, LogLevel.info) );
	
	Router
		.join(JSONRPCRouter)
		.join(PageRouter);
		
	Router.onError.join( (Throwable error, HTTPContext context) {
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = error.msg ~ "<br>\r\n" ~"Module: " ~ error.file ~ "(line: " ~ error.line.to!string ~ ") \r\n" ~ error.info.to!string;
		
		SiteLogger.error(msg);
		auto tpl = getGeneralTemplate(context);
		tpl.set( "content", "<h2>500 Internal Server Error</h2>\r\n" ~ msg );
		context.response ~= tpl.getString();
		return true;
	} );

	PageRouter.onPrePoll ~= (HTTPContext context) {
		PrioriteLogger.info( "context.request.headers: \r\n" ~ context.request.headers.getString() );
	};
	
	PageRouter.onError.join( (HTTPException error, HTTPContext context) {
		SiteLogger.warn("request.path: " ~ context.request.uri.path ~ "\r\n" ~ error.to!string);
		auto tpl = getGeneralTemplate(context);
		tpl.set( "content", "<h2>" ~ error.HTTPStatusCode.to!string
			~ " " ~ HTTPReasonPhrases[error.HTTPStatusCode] ~ "</h2>\r\n" ~ error.msg );
		context.response ~= tpl.getString();
		return true;
	} );
	
	auto accessController = new MKK_SiteAccessController;
	
	Router.onPostPoll ~= (HTTPContext context, bool isMatched) {
		if( isMatched )
		{	context._setuser( accessController.authenticate(context) );
		}
	};
	
	JSONRPCRouter.onError.join( (Throwable error, HTTPContext context) {
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = typeid(error).to!string;
		
		context.response ~= `{"jsonrpc":"2.0","error":{"msg":"`
		~ msg ~ `"}}`;
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