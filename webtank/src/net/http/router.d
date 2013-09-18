module webtank.net.http.router;

import std.json, std.stdio;

import webtank.net.json_rpc, webtank.net.http.request, webtank.net.http.response;

alias void function(ServerRequest, ServerResponse) ServerPathHandler;
alias JSONValue delegate(JSONValue) JSON_RPC_Method;

//Класс исключения при маршрутизации
class RoutingException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

//Класс, выполняющий роль маршрутизатора для соединений
//с сервером по протоколу HTTP
class Router
{	
protected:
	static {
		JSON_RPC_Method[string] _jrpcMethods;
		ServerPathHandler[string] _requestHandlers;
		bool _ignoreEndSlash = true;
	}

public:

static {
	//Регистрация обработчика HTTP запроса для заданного пути
	void setPathHandler(string path, ServerPathHandler handler)
	{	string clearPath = _normalizePagePath(path);
		if( clearPath in _requestHandlers )
			throw new RoutingException("Обработчик для пути \"" ~ clearPath ~ "\" уже зарегистрирован в системе!!!");
		else
			_requestHandlers[clearPath] = handler;
	}
	void setRPCMethod(MethodType)(string methodName, MethodType method)
	{	import std.traits, std.json, std.conv, std.typecons;
		alias ParameterTypeTuple!(MethodType) ParamTypes;
		alias Tuple!(ParamTypes) ArgTupleType;
		alias ReturnType!(method) ResultType;
		
		if( methodName in _requestHandlers )
			throw new RoutingException("JSON-RPC метод \"" ~ methodName ~ "\" уже зарегистрирован в системе!!!");
		
		JSONValue JSONMethod(JSONValue jsonArg)
		{	writeln("JSONMethod:  jsonArg");
			writeln( toJSON(&jsonArg) );
			auto argTuple = getDLangValue!( ArgTupleType )(jsonArg);
			
			static if( is( ResultType == void ) )
			{	method(); //Вызываем метод
				JSONValue result;
				result.type = JSON_TYPE.NULL;
				return result;
			}
			else
				return getJSONValue( method(argTuple.expand) );
		}
		
		_jrpcMethods[methodName] = &JSONMethod;
	}
	
	//Получить 
	ServerPathHandler getPathHandler(string path)
	{	return _requestHandlers.get( _normalizePagePath(path), null );
	}
	
	JSON_RPC_Method getRPCMethod(string methodName)
	{	return _jrpcMethods.get( methodName, null );
	}
	
	bool hasRPCMethod(string methodName)
	{	if( methodName in _jrpcMethods )
			return true;
		else
			return false;
	}
	
	bool hasPathHandler(string path)
	{	if( _normalizePagePath(path) in _jrpcMethods )
			return true;
		else
			return false;
	}
	
	void processRequest(ServerRequest request, ServerResponse response)
	{	string contentType = request.headers.get("content-type", "");
		if( contentType == "application/json-rpc" ) //Скорее всего JSON RPC
		{	import std.json;
			JSONValue jMessageBody;
			writeln(request.messageBody);
			try
			{	
				jMessageBody = parseJSON( request.messageBody );
			
			}
			catch(Exception e) 
			{	writeln("Ошибка при разборе строки JSON");
				
			}
			writeln(jMessageBody.type);
			if( jMessageBody.type == JSON_TYPE.ARRAY ) //Возможно, пакет пришёл
			{	//Пока не реализуем
				
			}
			else if( jMessageBody.type == JSON_TYPE.OBJECT )
			{	string methodName;
				writeln(_jrpcMethods);
				if( "method" in jMessageBody.object )
				{	if( jMessageBody.object["method"].type == JSON_TYPE.STRING )
						methodName = jMessageBody.object["method"].str;
				}
				string protocol;
				if( "jsonrpc" in jMessageBody.object )
				{	if( jMessageBody.object["jsonrpc"].type == JSON_TYPE.STRING )
						protocol = jMessageBody.object["jsonrpc"].str;
				}
				string id;
				if( "id" in jMessageBody.object )
				{	if( jMessageBody.object["id"].type == JSON_TYPE.STRING )
						id = jMessageBody.object["id"].str;
				}
				writeln(protocol ~ "  " ~ methodName ~ "  " ~ id );
				JSONValue params;
				if( "params" in jMessageBody.object )
				{	//TODO: Сделать, чтобы кроме массива мог быть любой другой тип
					//Для начала - любой кроме объекта
					if( jMessageBody.object["params"].type == JSON_TYPE.ARRAY )
					{	params = jMessageBody.object["params"];
						if( methodName.length > 0 && protocol == "2.0" )
						{	auto method = getRPCMethod(methodName);
							writeln(params);
							if( method !is null )
							{	JSONValue resultJSONValue;
								try {
									resultJSONValue = method( params );
								} catch( std.json.JSONException e ) {
									throw new JSON_RPC_Exception("Can't serialize method return value to JSON!!!\r\n" ~ e.msg);
								}
								string jStr = toJSON( &resultJSONValue );
								string responseStr = 
									`{"jsonrpc":"2.0","result":` ~ jStr ~ `,"error":null`
									~ ( id.length > 0 ? `,"id":"` ~ id ~ `"` : `` ) ~ `}`;
								writeln(responseStr);
								response.write( responseStr );
								response.flush();
							}
						}
					}
				}
			}
			//else //не JSON RPC
		}
		else //Какой-нибудь обычный text/html илм text/plain или application/x-www-form-urlencoded
		{	auto handler = getPathHandler(request.path);
			if( handler !is null )
			{	handler(request, response);	
				response.flush();
			}
		}
		
	}
}// static
	
protected:
	static string _normalizePagePath(string path)
	{	import std.string;
		import std.path;
		string clearPath = buildNormalizedPath( strip( path ) );
		version(Windows) {
			if ( _ignoreEndSlash && clearPath[$-1] == '\\' ) 
				return clearPath[0..$-1];
		}
		version(Posix) {
			if ( _ignoreEndSlash && clearPath[$-1] == '/')
				return clearPath[0..$-1];
		}
		return clearPath;
	}
	
}