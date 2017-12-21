module mkk_site.view_service.uri_page_router;

import webtank.net.http.context;
import webtank.net.http.handler;
import webtank.net.http.http;
import webtank.net.http.output;
import webtank.net.uri_pattern;

import mkk_site.view_service.service: Service;
import mkk_site.view_service.utils;
import ivy.interpreter.data_node;

alias TDataNode = DataNode!string;

import std.functional: toDelegate;
import std.traits: ReturnType, Parameters;
template join(alias Method)
	if(
		(is(ReturnType!(Method) == string) || is(ReturnType!(Method) == TDataNode))
		&& Parameters!(Method).length == 1 && is(Parameters!(Method)[0] : HTTPContext)
	)
{
	void _processRequest(HTTPContext context) {
		Service.renderResult(Method(context), context);
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