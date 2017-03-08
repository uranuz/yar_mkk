module mkk_site.view_service.uri_page_router;

import webtank.net.http.context, webtank.common.event, webtank.net.http.handler, webtank.net.http.http;
import webtank.net.uri_pattern;

import mkk_site.view_service.service: Service;
import mkk_site.view_service.utils;
import ivy.interpreter_data;

///Маршрутизатор запросов к страницам сайта по URI
class MKK_ViewService_URIPageRouter: EventBasedHTTPHandler
{	
	this( string URIPatternStr, string[string] regExprs, string[string] defaults )
	{	_uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
	}
	
	this( string URIPatternStr, string[string] defaults = null )
	{	this(URIPatternStr, null, defaults);
	}
	
	alias string delegate(HTTPContext) PageHandler;
	alias TDataNode = DataNode!string;
	
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
		context.response.tryClearBody();

		auto generalTpl = Service.templateCache.getByModuleName("mkk.general_template");
		TDataNode payload;
		payload["vpaths"] = TDataNode(Service.virtualPaths);
		payload["content"] = handler(context);

		if( context.user.isAuthenticated )
		{
			payload["authStateCls"] = "m-with_auth";
			payload["authPopdownBtnText"] = context.user.name;
			payload["authPopdownBtnTitle"] = "Открыть список опций для учетной записи";
		}
		else
		{
			payload["authStateCls"] = "m-without_auth";
			payload["authPopdownBtnText"] = "Вход не выполнен";
			payload["authPopdownBtnTitle"] = "Вход на сайт не выполнен";
		}

		auto favouriteFilters = mainServiceCall(`pohod.favoriteFilters`, context);
		assert( "sections" in favouriteFilters, `There is no "sections" property in pohod.favoriteFilters response` );
		assert( "allFields" in favouriteFilters, `There is no "allFields" property in pohod.favoriteFilters response` );

		payload["pohodFilterFields"] = favouriteFilters["allFields"];
		payload["pohodFilterSections"] = favouriteFilters["sections"];
		payload["pohodFiltersJSON"] = favouriteFilters["sections"].toJSONString();

		context.response.write( generalTpl.run(payload).str );
	}

	struct PageRoute
	{	URIPattern pattern;
		PageHandler handler;
	}
	
	template join(alias Method)
	{
		import std.functional: toDelegate;
		MKK_ViewService_URIPageRouter join(string URIPatternStr, string[string] regExprs, string[string] defaults)
		{	auto uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
			_pageRoutes ~= PageRoute( uriPattern, toDelegate( &Method ) );
			return this;
		}
		
		MKK_ViewService_URIPageRouter join(string URIPatternStr, string[string] defaults = null)
		{	return this.join!(Method)( URIPatternStr, null, defaults );
		}
	}
	
protected:
	PageRoute[] _pageRoutes;
	URIPattern _uriPattern;
}
