module mkk_site.view_service.utils;

import std.json;
import ivy;
import ivy.json;
import ivy.interpreter_data;

import webtank.net.http.client: sendJSON_RPCRequestAndWait;

/// Выполняет вызов метода rpcMethod по протоколу JSON-RPC с узла requestURI и параметрами jsonParams в формате JSON
/// Возвращает результат выполнения метода, разобранный в формате данных шаблонизатора Ivy
TDataNode sendJSON_RPCRequestAndWaitAsIvyNode( string requestURI, string rpcMethod, ref JSONValue jsonParams )
{
	auto response = sendJSON_RPCRequestAndWait(requestURI, rpcMethod, jsonParams);

	TDataNode ivyJSON = parseIvyJSON(response.messageBody);
	assert( ivyJSON.type == DataNodeType.AssocArray, `Expected assoc array as JSON-RPC result` );
	assert( "result" in ivyJSON.assocArray, `Expected "result" field in JSON-RPC result` );
	
	return ivyJSON["result"];
}

// То же самое, что sendJSON_RPCRequestAndWaitAsIvyNode, но делает вызов с основного сервиса МКК
TDataNode callMainServiceMethodAndWaitAsIvyNode( string rpcMethod, JSONValue jsonParams = JSONValue.init ) {
	return sendJSON_RPCRequestAndWaitAsIvyNode(`http://localhost/jsonrpc/`, rpcMethod, jsonParams);
}

/// То же самое, что sendJSON_RPCRequestAndWaitAsIvyNode, но возвращает результат в формате std.json
JSONValue sendJSON_RPCRequestAndWaitAsJSON( string requestURI, string rpcMethod, ref JSONValue jsonParams )
{
	auto response = sendJSON_RPCRequestAndWait(requestURI, rpcMethod, jsonParams);

	JSONValue bodyJSON = response.bodyJSON;
	assert( bodyJSON.type == JSON_TYPE.OBJECT, `Expected object as JSON-RPC result` );
	assert( "result" in bodyJSON, `Expected "result" field in JSON-RPC result` );

	return bodyJSON["result"];
}

/// То же самое, что sendJSON_RPCRequestAndWaitAsJSON, но делает вызов с основного сервиса МКК
JSONValue callMainServiceMethodAndWaitAsJSON( string rpcMethod, JSONValue jsonParams = JSONValue.init ) {
	return sendJSON_RPCRequestAndWaitAsJSON(`http://localhost/jsonrpc/`, rpcMethod, jsonParams);
}