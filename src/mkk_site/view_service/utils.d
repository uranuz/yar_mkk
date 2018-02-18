module mkk_site.view_service.utils;

import std.json;
import ivy;
import ivy.json;
import ivy.interpreter.data_node;

import webtank.net.http.context: HTTPContext;
import webtank.net.std_json_rpc_client;
import webtank.ivy.rpc_client;

private __gshared _mainServiceEndpoint = `http://localhost/jsonrpc/`;

// То же самое, что remoteCall, но делает вызов с основного сервиса МКК
Result mainServiceCall(Result = TDataNode)( string rpcMethod, string[string] headers, JSONValue params = JSONValue.init )
	if( is(Result == TDataNode) || is(Result == JSONValue) )
{
	return remoteCall!(Result)(_mainServiceEndpoint, rpcMethod, headers, params);
}

// Перегрузка mainServiceCall для удобства, которая позволяет передать HTTP контекст для извлечения заголовков
Result mainServiceCall(Result = TDataNode)( string rpcMethod, HTTPContext context, JSONValue params = JSONValue.init )
	if( is(Result == TDataNode) || is(Result == JSONValue) )
{
	assert( context !is null, `HTTP context is null` );
	return remoteCall!(Result)(_mainServiceEndpoint, rpcMethod, context, params);
}