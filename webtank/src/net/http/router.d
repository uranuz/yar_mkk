module webtank.net.http.router;

import webtank.net.json_rpc;

alias void function(http.ServerRequest, http.ServerResponse) ServerRequestHandler;
alias void delegate(JSONValue) JSON_RPC_Method;

//Класс, выполняющий роль маршрутизатора для соединений
//с сервером по протоколу HTTP
static class Router
{	
protected:
	JSON_RPC_Method[string] _jrpcMethods;
	ServerRequestHandler[string] _requestHandlers;
	bool _ignoreEndSlash = true;

public:

	void registerRequestHandler(string path, ServerRequestHandler handler)
	{	string clearPath = _normalizePagePath(path);
		_requestHandlers[clearPath] = &handler;
	}
	void registerRPCMethod(MethodType)(string methodName)
	{	import std.traits, std.json, std.conv;
		alias ParameterTypeTuple!(MethodType) ParamTypes;
		alias Tuple!(ParamTypes) ArgTupleType;
	// 	alias ReturnType!(MethodType) ResultType;
		
		void JSONMethod(JSONValue jsonArg)
		{	auto argTuple = getJSONValue!( ArgTupleType )(jsonArg);
			method(argTuple.expand);
		}
		
		_jrpcMethods[methodName] = &JSONMethod;
	}
	
	ServerRequestHandler getRequestHandler(string path)
	{	string clearPath = _normalizePagePath(path);
		return _requestHandlers.get(clearPath, null);
	}
	
	JSON_RPC_Method getRPCMethod(string methodName)
	{	return _requestHandlers.get(methodName, null);
	}
	
protected:
	string _normalizePagePath(string path)
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