module mkk_site.routing_init;

import
	webtank.net.http.handler, 
	webtank.net.http.json_rpc_handler,
	webtank.net.http.context, 
	webtank.net.http.http;

import 
	mkk_site.site_data_old,
	mkk_site.access_control,
	mkk_site.utils,
	mkk_site.uri_page_router,
	mkk_site.logging,
	mkk_site.templating;

import mkk_site.routing;

string makeExtendedErrorMsg( Throwable error )
{
	import std.conv;
	return error.msg ~ "<br>\r\n" ~"Module: " ~ error.file ~ "(" ~ error.line.to!string ~ ") \r\n" ~ error.info.to!string;
}

//Инициализация маршрутизации сайта МКК
shared static this()
{	
	import std.exception: assumeUnique;
	import std.conv;
	
	Router = new HTTPRouter;
	PageRouter = new MKK_Site_URIPageRouter( dynamicPath ~ "{remainder}" );
	JSONRPCRouter = new JSON_RPC_Router( JSON_RPC_Path ~ "{remainder}" );

	Router
		.join(JSONRPCRouter)
		.join(PageRouter);
	
	//Для сообщений об ошибках базового класса Throwable не используем шаблон страницы,
	//поскольку нить исполнения находится в некорректном состоянии
	Router.onError.join( (Throwable error, HTTPContext context) {
		string extendedMsg = makeExtendedErrorMsg(error);
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = extendedMsg;
		
		PrioriteLoger.error(extendedMsg);
		SiteLoger.error(extendedMsg);
		//context.response ~= "<h2>500 Internal Server Error</h2>\r\n" ~ msg;
		throw error;
		return true; //Dummy error
	} );
	
	//Обработка "обычных" исключений
	Router.onError.join( (Exception error, HTTPContext context) {
		string extendedMsg = makeExtendedErrorMsg(error);
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = extendedMsg;
		
		SiteLoger.error(extendedMsg);
		auto tpl = getGeneralTemplate(context);
		tpl.set( "content", "<h2>500 Internal Server Error</h2>\r\n" ~ msg );
		context.response ~= tpl.getString();
		return true;
	} );

	PageRouter.onPrePoll ~= (HTTPContext context) {
		PrioriteLoger.info( "context.request.headers: \r\n" ~ context.request.headers.getString() );
	};
	
	//Обработка HTTP ошибок
	PageRouter.onError.join( (HTTPException error, HTTPContext context) {
		SiteLoger.warn("request.path: " ~ context.request.uri.path ~ "\r\n" ~ error.to!string);
		auto tpl = getGeneralTemplate(context);
		tpl.set( "content", "<h2>" ~ error.HTTPStatusCode.to!string
			~ " " ~ HTTPReasonPhrases.get(error.HTTPStatusCode, null) ~ "</h2>\r\n" ~ error.msg );
		context.response ~= tpl.getString();
		return true;
	} );

	auto accessController = new MKKMainAccessController;
	
	Router.onPostPoll ~= (HTTPContext context, bool isMatched) {
		if( isMatched )
		{	context._setuser( accessController.authenticate(context) );
		}
	};
	
	//Обработка ошибок в JSON-RPC вызовах
	JSONRPCRouter.onError.join( (Throwable error, HTTPContext context) {
		string extendedMsg = makeExtendedErrorMsg(error);
		static if( isMKKSiteReleaseTarget )
			string msg = error.msg;
		else
			string msg = extendedMsg;
		
		PrioriteLoger.error(extendedMsg);
		SiteLoger.error(extendedMsg);
		//context.response ~= `{"jsonrpc":"2.0","error":{"msg":"` ~ msg ~ `"}}`;
		throw error;
		return true; //Dummy return
	} );
}