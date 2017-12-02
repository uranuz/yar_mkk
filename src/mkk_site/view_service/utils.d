module mkk_site.view_service.utils;

import std.json;
import ivy;
import ivy.json;
import ivy.interpreter.data_node;

import webtank.net.http.context: HTTPContext;
import webtank.net.http.input: HTTPInput;
import webtank.net.http.client: sendJSON_RPCBlockingA = sendJSON_RPCBlocking;
import mkk_site.view_service.ivy_custom;

private bool _isContainerRawData(ref TDataNode srcNode) {
	return
		srcNode.type == DataNodeType.AssocArray
		&& "t" in srcNode 
		&& srcNode["t"].type == DataNodeType.String;
}

auto tryExtractRecordSet(ref TDataNode srcNode)
{
	if( !_isContainerRawData(srcNode) && srcNode["t"].str != "recordset" ) {
		return null;
	}
	return new RecordSetAdapter(srcNode);
}

auto tryExtractRecord(ref TDataNode srcNode)
{
	if( !_isContainerRawData(srcNode) && srcNode["t"].str != "record" ) {
		return null;
	}
	return new RecordAdapter(srcNode);
}

TDataNode tryExtractContainer(ref TDataNode srcNode)
{
	if( !_isContainerRawData(srcNode) ) {
		return srcNode;
	}

	switch( srcNode["t"].str )
	{
		case "recordset":
			return TDataNode(new RecordSetAdapter(srcNode));
		case "record":
			return TDataNode(new RecordAdapter(srcNode));
		default: break;
	}
	return srcNode;
}

TDataNode tryExtractLvlContainers(TDataNode srcNode)
{
	srcNode = srcNode.tryExtractContainer();
	if( srcNode.type != DataNodeType.AssocArray )
		return srcNode;

	foreach( key, item; srcNode.assocArray ) {
		srcNode.assocArray[key] = srcNode.assocArray[key].tryExtractContainer();
	}
	return srcNode;
}

class OverridenTraceInfo: object.Throwable.TraceInfo
{
	private char[][] _backTrace;
	this(char[][] traceInfo) {
		_backTrace = traceInfo;
	}

	override {
		int opApply(scope int delegate(ref const(char[])) dg) const
		{
			int result = 0;
			foreach( i; 0.._backTrace.length )
			{
				result = dg(_backTrace[i]);
				if (result)
					break;
			}
			return result;
		}
		int opApply(scope int delegate(ref size_t, ref const(char[])) dg) const
		{
			int result = 0;
			foreach( i; 0.._backTrace.length )
			{
				result = dg(i, _backTrace[i]);
				if (result)
					break;
			}
			return result;
		}
		string toString() const
		{
			import std.array: join;
			return cast(string) _backTrace.join('\n');
		}
	}
}

// Код проверки результата запроса по протоколу JSON-RPC
// По сути этот код дублирует webtank.net.http.client, но с другим типом данных
private void _checkJSON_RPCErrors(ref TDataNode response)
{
	import std.algorithm: map;
	import std.array: array;
	if( response.type != DataNodeType.AssocArray )
		throw new Exception(`Expected assoc array as JSON-RPC response`);

	if( "error" in response )
	{
		if( response["error"].type != DataNodeType.AssocArray ) {
			throw new Exception(`"error" field in JSON-RPC response must be an object`);
		}
		string errorMsg;
		if( "message" in response["error"] ) {
			errorMsg = response["error"]["message"].type == DataNodeType.String? response["error"]["message"].str: null;
		}

		if( "data" in response["error"] )
		{
			TDataNode errorData = response["error"]["data"];
			if(
				"file" in errorData &&
				"line" in errorData &&
				errorData["file"].type == DataNodeType.String &&
				errorData["line"].type == DataNodeType.Integer
			) {
				Exception ex = new Exception(errorMsg, errorData["file"].str, errorData["line"].integer);
				if( "backtrace" in errorData && errorData["backtrace"].type == DataNodeType.Array ) {
					ex.info = new OverridenTraceInfo(errorData["backtrace"].array.map!( (it) => it.str.dup ).array );
				}
				throw ex;
			}
		}

		throw new Exception(errorMsg);
	}

	if( "result" !in response )
		throw new Exception(`Expected "result" field in JSON-RPC response`);
}

/// Выполняет вызов метода rpcMethod по протоколу JSON-RPC с узла requestURI и параметрами jsonParams в формате JSON
/// Возвращает результат выполнения метода, разобранный в формате данных шаблонизатора Ivy
TDataNode sendJSON_RPCBlocking(Result)( string requestURI, string rpcMethod, ref JSONValue jsonParams )
	if( is(Result == TDataNode) )
{
	auto response = sendJSON_RPCBlockingA!(HTTPInput)(requestURI, rpcMethod, jsonParams);

	TDataNode ivyJSON = parseIvyJSON(response.messageBody);
	_checkJSON_RPCErrors(ivyJSON);

	return ivyJSON["result"].tryExtractLvlContainers();
}

// Перегрузка sendJSON_RPCBlocking, которая позволяет передать словарь с HTTP заголовками
TDataNode sendJSON_RPCBlocking(Result)( string requestURI, string rpcMethod, string[string] headers, ref JSONValue jsonParams )
	if( is(Result == TDataNode) )
{
	auto response = sendJSON_RPCBlockingA!(HTTPInput)(requestURI, rpcMethod, headers, jsonParams);

	TDataNode ivyJSON = parseIvyJSON(response.messageBody);
	_checkJSON_RPCErrors(ivyJSON);

	return ivyJSON["result"].tryExtractLvlContainers();
}

private static immutable _mainServiceEndpoint = `http://localhost/jsonrpc/`;

// То же самое, что sendJSON_RPCBlocking, но делает вызов с основного сервиса МКК
TDataNode mainServiceCall( string rpcMethod, string[string] headers, JSONValue jsonParams = JSONValue.init ) {
	return sendJSON_RPCBlocking!(TDataNode)(_mainServiceEndpoint, rpcMethod, jsonParams);
}

/// То же самое, что sendJSON_RPCBlocking, но делает вызов с основного сервиса МКК
JSONValue mainServiceCall(Result)( string rpcMethod, string[string] headers, JSONValue jsonParams = JSONValue.init )
	if( is(Result == JSONValue) )
{
	return sendJSON_RPCBlockingA(_mainServiceEndpoint, rpcMethod, jsonParams);
}

private static immutable _allowedHeaders = [
	`user-agent`, `cookie`, `x-real-ip`, `x-forwarded-for`, `x-forwarded-proto`, `x-forwarded-host`, `x-forwarded-port`
];
/// Извлекает разрешенные HTTP заголовки из запроса
private string[string] _getAllowedRequestHeaders(HTTPContext ctx)
{
	auto headers = ctx.request.headers;

	string[string] result;
	foreach( name; _allowedHeaders )
	{
		if( name in headers ) {
			result[name] = headers[name];
		}
	}

	return result;
}

// Перегрузка mainServiceCall для удобства, которая позволяет передать HTTP контекст для извлечения заголовков
TDataNode mainServiceCall( string rpcMethod, HTTPContext context, JSONValue jsonParams = JSONValue.init ) {
	assert( context !is null, `HTTP context is null` );
	return sendJSON_RPCBlocking!(TDataNode)(_mainServiceEndpoint, rpcMethod, _getAllowedRequestHeaders(context), jsonParams);
}

/// Перегрузка mainServiceCall для возврата данных в виде std.json
JSONValue mainServiceCall(Result)( string rpcMethod, HTTPContext context, JSONValue jsonParams = JSONValue.init )
	if( is(Result == JSONValue) )
{
	assert( context !is null, `HTTP context is null` );
	return sendJSON_RPCBlockingA(_mainServiceEndpoint, rpcMethod, _getAllowedRequestHeaders(context), jsonParams);
}