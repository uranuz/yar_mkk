module mkk_site.view_service.uri_page_router;

import webtank.net.http.context;
import webtank.common.event;
import webtank.net.http.handler;
import webtank.net.http.http;
import webtank.net.http.output;
import webtank.net.uri_pattern;

import mkk_site.view_service.service: Service;
import mkk_site.view_service.utils;
import mkk_site.common.utils: getAuthRedirectURI;
import ivy.interpreter.data_node;
import ivy.interpreter.data_node_render;

alias TDataNode = DataNode!string;

void _renderMessageBody(MKKPageHandler)(MKKPageHandler handler, HTTPContext context)
{
	import std.string: toLower;
	context.response.tryClearBody();

	TDataNode payload;
	if( context.request.queryForm.get("generalTemplate", null).toLower() == "no" ) {
		payload = handler(context);
	}
	else
	{
		TDataNode dataDict;
		dataDict["vpaths"] = TDataNode(Service.virtualPaths);
		dataDict["content"] = handler(context);
		dataDict["isAuthenticated"] = context.user.isAuthenticated;
		dataDict["userName"] = context.user.name;
		dataDict["authRedirectURI"] = getAuthRedirectURI(context);

		auto favouriteFilters = mainServiceCall(`pohod.favoriteFilters`, context);
		assert("sections" in favouriteFilters, `There is no "sections" property in pohod.favoriteFilters response`);
		assert("allFields" in favouriteFilters, `There is no "allFields" property in pohod.favoriteFilters response`);

		dataDict["pohodFilterFields"] = favouriteFilters["allFields"];
		dataDict["pohodFilterSections"] = favouriteFilters["sections"];

		payload = Service.templateCache.getByModuleName("mkk.GeneralTemplate").run(dataDict);
	}

	static struct OutRange
	{
		private HTTPOutput _resp;
		void put(T)(T data) {
			import std.conv: text;
			_resp.write(data.text);
		}
	}

	renderDataNode!(DataRenderType.HTML)(payload, OutRange(context.response));
}

import std.functional: toDelegate;
import std.traits: ReturnType, Parameters;
template join(alias Method)
	if(
		(is(ReturnType!(Method) == string) || is(ReturnType!(Method) == TDataNode))
		&& Parameters!(Method).length == 1 && is(Parameters!(Method)[0] : HTTPContext)
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