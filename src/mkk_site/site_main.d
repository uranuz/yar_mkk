module mkk_site.site_main;

import std.conv, std.getopt;

import webtank.net.web_server, webtank.net.http.handler, webtank.net.http.json_rpc_handler,
webtank.net.http.context, webtank.net.http.http, webtank.templating.plain_templater;

import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, mkk_site.uri_page_router, webtank.common.logger;

enum useTemplateCache = !isMKKSiteDevelTarget;

__gshared PlainTemplateCache!(useTemplateCache) templateCache; 

shared static this()
{
	templateCache = new PlainTemplateCache!(useTemplateCache)();
}


__gshared HTTPRouter Router;
__gshared MKK_Site_URIPageRouter PageRouter;
__gshared JSON_RPC_Router JSONRPCRouter;
__gshared Logger SiteLogger;
__gshared Logger PrioriteLogger;

//Инициализация сайта МКК
shared static this()
{	
	import std.exception: assumeUnique;
	Router = new HTTPRouter;
	PageRouter = new MKK_Site_URIPageRouter( dynamicPath ~ "{remainder}" );
	JSONRPCRouter = new JSON_RPC_Router( JSON_RPC_Path ~ "{remainder}" );
	
	static if( isMKKSiteReleaseTarget )
	{
		enum siteLogLevel = LogLevel.error;
		enum prioriteLogLevel = LogLevel.info;
	}
	else
	{
		enum siteLogLevel = LogLevel.info;
		enum prioriteLogLevel = LogLevel.info;
	}
	
	SiteLogger = new ThreadedLogger( cast(shared) new FileLogger(eventLogFileName, siteLogLevel) );
	PrioriteLogger = new ThreadedLogger( cast(shared) new FileLogger(prioriteLogFileName, prioriteLogLevel) );
	
	Router
		.join(JSONRPCRouter)
		.join(PageRouter);
	
	//Для сообщений об ошибках базового класса Throwable не используем шаблон страницы,
	//поскольку нить исполнения находится в некорректном состоянии
	Router.onError.join( (Throwable error, HTTPContext context) {
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = error.msg ~ "<br>\r\n" ~"Module: " ~ error.file ~ "(line: " ~ error.line.to!string ~ ") \r\n" ~ error.info.to!string;
		
		SiteLogger.error(msg);
		context.response ~= "<h2>500 Internal Server Error</h2>\r\n" ~ msg;
		return true;
	} );
	
	//Обработка "обычных" исключений
	Router.onError.join( (Exception error, HTTPContext context) {
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
	
	//Обработка HTTP ошибок
	PageRouter.onError.join( (HTTPException error, HTTPContext context) {
		SiteLogger.warn("request.path: " ~ context.request.uri.path ~ "\r\n" ~ error.to!string);
		auto tpl = getGeneralTemplate(context);
		tpl.set( "content", "<h2>" ~ error.HTTPStatusCode.to!string
			~ " " ~ HTTPReasonPhrases.get(error.HTTPStatusCode, null) ~ "</h2>\r\n" ~ error.msg );
		context.response ~= tpl.getString();
		return true;
	} );
	
	
	auto accessController = new MKK_SiteAccessController;
	
	Router.onPostPoll ~= (HTTPContext context, bool isMatched) {
		if( isMatched )
		{	context._setuser( accessController.authenticate(context) );
		}
	};
	
	//Обработка ошибок в JSON-RPC вызовах
	JSONRPCRouter.onError.join( (Throwable error, HTTPContext context) {
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = error.msg ~ "Module: " ~ error.file ~ "(line: " ~ error.line.to!string ~ ") \r\n" ~ error.info.to!string;
		
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