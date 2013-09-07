module webtank.net.http.connection;

import std.socket;


alias void function(HTTPConnection) HTTPConnectionHandler;


class HTTPConnection
{	
protected:
	Socket _socket;
	static shared(HTTPConnectionHandler[string]) _handlers;
	bool _ignoreEndSlash = true;
	
	
public:
	this( Socket s )
	{	_socket = s;
		
	}
	
	
	
	string _normalizePagePath(string path, bool ignoreEndSlash = true)
	{	import std.string;
		import std.path;
		string clearPath = buildNormalizedPath( strip( path ) );
		version(Windows) {
			if ( ignoreEndSlash && clearPath[$-1] == '\\' ) 
				return clearPath[0..$-1];
		}
		version(Posix) {
			if ( ignoreEndSlash && clearPath[$-1] == '/')
				return clearPath[0..$-1];
		}
		return clearPath;
	}
	
	static void registerHandler(string path, HTTPConnectionHandler handler)
	{	string clearPath = _normalizePagePath(path, _ignoreEndSlash);
		synchronized {
			_handlers[path] = handler;
		}
	}
	
	template registerMethod(MethodType)
	{	import std.traits, std.json, std.conv;
		alias ParameterTypeTuple!(MethodType) ParamTypes;
		static if( ParamTypes.length == 1)
		{	static if( is( ParamTypes[0] : string ) )
			{	static void registerMethod(string methodName, MethodType)
				{
					
					
				}
				
				
			}
			else static if( is( ParamTypes[0] : JSONValue ) )
			{
			
			
			}
			else
				static assert( 0, `Method "registerMethod" is not implemented for method type ` ~ typeid(MethodType).to!string );
	
		}
		else
			static assert( 0, `Method "registerMethod" is not implemented for number of method's parameters ` ~ ParamTypes.length.to!string );
	}
	
	
	void _run()
	{	scope(exit) _finalize(); //Завершение потока при выходе из _run
		size_t bytesRead;
		char[] startBuf;
		startBuf.length = startBufLength;
		
		//Читаем из сокета в буфер
		bytesRead = _socket.receive(startBuf);
		//TODO: Проверить сколько байт прочитано
		
		auto headers = new RequestHeaders(startBuf.idup);
		
		if( headers.errorCode != 0 )
		{	_socket.sendTo( generateServicePage(headers.errorCode) );
			return;
		}
		
		string path;
		if( headers["request-uri"] !is null )
		{	path = separatePath( headers["request-uri"] );
		}
		
		auto handler = Application.getHandler(path); //Получаем обработчик для пути
		if( handler is null ) 
		{	_socket.sendTo( generateServicePage(404) );
			return;
		}
		
		//Определяем длину тела запроса
		size_t contentLength = 0;
		if( headers["content-length"] !is null )
		{	try {
				contentLength = headers["content-length"].to!size_t;
			} catch(Exception e) { contentLength = 0; }
		}
		
		//Проверяем размер тела запроса
		if( contentLength > messageBodyLimit )
		{	_socket.sendTo( generateServicePage(413) );
			return;
		}
		
// 		write("headers.strLength: "); writeln( headers.strLength );
		
		string messageBody;
		char[] bodyBuf;
		size_t extraBytesInHeaderBuf = startBuf.length - headers.strLength;
// 		write("extraBytesInHeaderBuf: "); writeln( extraBytesInHeaderBuf );
		//Нужно определить сколько ещё нужно прочитать
		if( contentLength > extraBytesInHeaderBuf )
		{	bodyBuf.length = contentLength - extraBytesInHeaderBuf;
			_socket.receive(bodyBuf);
			messageBody = headers.extraData ~ bodyBuf.idup;
// 			writeln("contentLength > extraBytesInHeaderBuf");
		}
		else
		{	messageBody = headers.extraData[0..contentLength];
// 			writeln("contentLength < extraBytesInHeaderBuf");
		}
// 		write("messageBody.length: "); writeln( messageBody.length ); 
		
		//Загоняем данные в объект Application
		auto app = new Application( handler );
		app.request = new Request( headers, messageBody );
		app.response = new Response( &this._write );
		
		app.run(); //Запускаем объект
		scope(exit) app._finalize(); //Завершаем объект
	}
	
	//Выводит данные в сокет
	void _write(string message)
	{	_socket.sendTo(message);
	}
	
	void _finalize()
	{	_socket.shutdown(SocketShutdown.BOTH);
		_socket.close();
		_socket.destroy();
	}
	
	
}