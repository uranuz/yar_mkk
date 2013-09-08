module webtank.net.http.router;

import std.json, std.stdio;

import webtank.net.json_rpc, webtank.net.http.request, webtank.net.http.response;

alias void function(ServerRequest, ServerResponse) ServerRequestHandler;
alias void delegate(JSONValue) JSON_RPC_Method;

//Класс, выполняющий роль маршрутизатора для соединений
//с сервером по протоколу HTTP
class Router
{	
protected:
	static {
		JSON_RPC_Method[string] _jrpcMethods;
		ServerRequestHandler[string] _requestHandlers;
		bool _ignoreEndSlash = true;
	}

public:

static {
	void registerRequestHandler(string path, ServerRequestHandler handler)
	{	string clearPath = _normalizePagePath(path);
		_requestHandlers[clearPath] = handler;
	}
	void registerRPCMethod(MethodType)(string methodName, MethodType method)
	{	import std.traits, std.json, std.conv, std.typecons;
		alias ParameterTypeTuple!(MethodType) ParamTypes;
		alias Tuple!(ParamTypes) ArgTupleType;
	// 	alias ReturnType!(MethodType) ResultType;
		
		void JSONMethod(JSONValue jsonArg)
		{	writeln("What a hell?!");
			auto argTuple = getJSONValue!( ArgTupleType )(jsonArg);
			
			method(argTuple.expand);
		}
		
		_jrpcMethods[methodName] = &JSONMethod;
	}
	
	ServerRequestHandler getRequestHandler(string path)
	{	string clearPath = _normalizePagePath(path);
		return _requestHandlers.get(clearPath, null);
	}
	
	JSON_RPC_Method getRPCMethod(string methodName)
	{	return _jrpcMethods.get(methodName, null);
	}
	
	void processRequest(ServerRequest request, ServerResponse response)
	{	string contentType = request.headers.get("content-type", "");
		writeln("processRequest");
		if( contentType == "application/json" ) //Скорее всего JSON RPC
		{	import std.json;
			JSONValue jMessageBody;
			try
			{	jMessageBody = parseJSON( request.messageBody );
			
			}
			catch(Exception e) 
			{	
				
			}
			if( jMessageBody.type == JSON_TYPE.ARRAY ) //Возможно, пакет пришёл
			{	//Пока не реализуем
				
			}
			else if( jMessageBody.type == JSON_TYPE.OBJECT )
			{	string methodName;
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
						protocol = jMessageBody.object["id"].str;
				}
				writeln("jsonrpc");
				JSONValue params;
				if( "params" in jMessageBody.object )
				{	if( jMessageBody.object["params"].type == JSON_TYPE.ARRAY )
					{	if( methodName.length > 0 && protocol.length > 0 )
						{	auto method = getRPCMethod(methodName);
							writeln("jsonrpc2");
							writeln(methodName);
							writeln(method);
							writeln( method is null );
// 							if( method !is null )
								method( params );
						}
					}
				}
			}
			//else //не JSON RPC
		}
		else //Какой-нибудь обычный text/html илм text/plain или application/x-www-form-urlencoded
		{	auto path = request.headers.get("request-uri", "");
			writeln(path);
			auto handler = getRequestHandler(path);
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