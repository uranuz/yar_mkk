module mkk_site.view_service.utils;

import std.json;
import ivy;
import ivy.json;
import ivy.interpreter.data_node;

import webtank.net.http.context: HTTPContext;
import webtank.net.http.handler: ICompositeHTTPHandler, URIPageRoute;
import webtank.net.http.http;
import webtank.net.uri_pattern: URIPattern;
import webtank.net.std_json_rpc_client;
import webtank.ivy.rpc_client;
import mkk_site.common.service: Service, endpoint;
import mkk_site.view_service.service: ViewService;
import webtank.net.service.endpoint;
import ivy.interpreter.data_node: DataNode;

// То же самое, что remoteCall, но делает вызов с основного сервиса МКК
Result mainServiceCall(Result = TDataNode)( string rpcMethod, string[string] headers, JSONValue params = JSONValue.init )
	if( is(Result == TDataNode) || is(Result == JSONValue) )
{
	return endpoint(`yarMKKMain`).remoteCall!(Result)(rpcMethod, headers, params);
}

// Перегрузка mainServiceCall для удобства, которая позволяет передать HTTP контекст для извлечения заголовков
Result mainServiceCall(Result = TDataNode)( string rpcMethod, HTTPContext context, JSONValue params = JSONValue.init )
	if( is(Result == TDataNode) || is(Result == JSONValue) )
{
	assert( context !is null, `HTTP context is null` );
	return endpoint(`yarMKKMain`).remoteCall!(Result)(rpcMethod, context, params);
}

alias TDataNode = DataNode!string;

import std.traits: ReturnType, Parameters;
template join(alias Method)
	if(
		(is(ReturnType!(Method) == string) || is(ReturnType!(Method) == TDataNode))
		&& Parameters!(Method).length == 1 && is(Parameters!(Method)[0] : HTTPContext)
	)
{
	void _processRequest(HTTPContext context) {
		ViewService.renderResult(Method(context), context);
	}

	import std.functional: toDelegate;
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