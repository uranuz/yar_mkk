module mkk_site.uri_page_router;

import std.conv;

import webtank.net.http.context, webtank.common.event, webtank.net.http.handler, webtank.net.http.http;
import webtank.net.uri_pattern;

import mkk_site.utils;

///Маршрутизатор запросов к страницам сайта по URI
class MKK_Site_URIPageRouter: EventBasedHTTPHandler
{	
	this( string URIPatternStr, string[string] regExprs, string[string] defaults )
	{	_uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
	}
	
	this( string URIPatternStr, string[string] defaults = null )
	{	this(URIPatternStr, null, defaults);
	}
	
	alias string delegate(HTTPContext) PageHandler;
	
	override HTTPHandlingResult customProcessRequest( HTTPContext context )
	{	auto uriData = _uriPattern.match(context.request.uri.path);

		onPostPoll.fire(context, uriData.isMatched);
		
		if( !uriData.isMatched )
			return HTTPHandlingResult.mismatched;
		
		//Перебор маршрутов к страницам
		foreach( ref route; _pageRoutes )
		{	auto pageURIData = route.pattern.match(context.request.uri.path);

			if( pageURIData.isMatched )
			{
				renderMessageBody(route.handler, context);
				return HTTPHandlingResult.handled; //Запрос обработан
			}
		}
		return HTTPHandlingResult.unhandled; //Запрос не обработан этим узлом
	}
	
	void renderMessageBody(PageHandler handler, HTTPContext context)
	{
		auto commonDB = getCommonDB();
		auto authDB = getAuthDB();
		
		if( !commonDB.isConnected || !authDB.isConnected )
			context.response.write("<h3>Ошибка соединения с базой данных!!!</h3>");
			
		import webtank.templating.plain_templater: PlainTemplater;
		import mkk_site.site_data;
		import mkk_site.templating;
		
		PlainTemplater tpl;
		
		if( context.request.bodyForm.get("for_print", null) == "on" )
			tpl = getPageTemplate(printGeneralTemplateFileName);
		else
			tpl = getGeneralTemplate(context);
		
		string content = handler(context);

		tpl.set( "content", content );
		context.response.tryClearBody();
		context.response.write( tpl.getString() );
	}

	struct PageRoute
	{	URIPattern pattern;
		PageHandler handler;
	}
	
	template join(alias Method)
	{	import std.functional;
		MKK_Site_URIPageRouter join(string URIPatternStr, string[string] regExprs, string[string] defaults)
		{	auto uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
			_pageRoutes ~= PageRoute( uriPattern, toDelegate( &Method ) );
			return this;
		}
		
		MKK_Site_URIPageRouter join(string URIPatternStr, string[string] defaults = null)
		{	return this.join!(Method)( URIPatternStr, null, defaults );
		}
	}
	
protected:
	PageRoute[] _pageRoutes;
	URIPattern _uriPattern;
}
