module mkk_site.view_service.uri_page_router;

import webtank.net.http.context, webtank.common.event, webtank.net.http.handler, webtank.net.http.http;
import webtank.net.uri_pattern;

import mkk_site.view_service.service: Service;
import mkk_site.view_service.utils;
import ivy.interpreter_data;

alias MKKPageHandler = string delegate(HTTPContext);
void _renderMessageBody(MKKPageHandler handler, HTTPContext context)
{
	alias TDataNode = DataNode!string;
	context.response.tryClearBody();

	auto generalTpl = Service.templateCache.getByModuleName("mkk.GeneralTemplate");
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

import std.functional: toDelegate;
import std.traits: ReturnType, Parameters;
template join(alias Method)
	if(
		is(ReturnType!(Method) == string) && Parameters!(Method).length == 1 && is(Parameters!(Method)[0] : HTTPContext)
	)
{
	void _processRequest(HTTPContext context) {
		_renderMessageBody(toDelegate(&Method), context);
	}

	import webtank.net.uri_pattern: URIPattern;
	ICompositeHTTPHandler join(ICompositeHTTPHandler parentHdl, string uriPatternStr)
	{
		parentHdl.addHandler(new URIPageRoute(toDelegate(&_processRequest), uriPatternStr));
		return parentHdl;
	}
	
	ICompositeHTTPHandler join(ICompositeHTTPHandler parentHdl, URIPattern uriPattern)
	{
		parentHdl.addHandler(new URIPageRoute(toDelegate(&_processRequest), uriPattern));
		return parentHdl;
	}
}