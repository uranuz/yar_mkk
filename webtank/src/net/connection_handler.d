module webtank.net.connection_handler;

import std.conv, std.stdio;

import webtank.net.application, webtank.net.uri, webtank.net.http_headers, 
webtank.net.request, webtank.net.response;

alias void function(Application) handlerFuncType;

interface IConnectionHandler
{	
	//static void setHandler(handlerFuncType connHandler, string path);
	void write(string message);
	void run();
	void finalize();
}

class HTTPConnectionHandler: IConnectionHandler
{	
	import std.socket;
	this(Socket socket)
	{	_socket = socket;
	}

	
		static void setHandler(handlerFuncType connHandler, string path)
		{	if( path in _handlerFunctions )
				assert(0, "Обработчик для пути: '" ~ path ~ "' уже зарегистрирован!!!");
			else
				_handlerFunctions[path] = connHandler;
		}
		
	override {
		//Выводит данные в сокет
		void write(string message)
		{	_socket.sendTo(message);
		}
		
		void run()
		{	size_t bytesRead;
			char[] headerBuf;
			headerBuf.length = 1024;
			
			//Читаем из сокета в буфер
			bytesRead = _socket.receive(headerBuf);
			//TODO: Проверить сколько байт прочитано
			
			auto headers = new HTTPHeaders(headerBuf.idup);
			
			string path;
			if( headers["request-uri"] !is null )
			{	path = separatePath( headers["request-uri"] );
				writeln(path);
			}
			
			if( path !in _handlerFunctions ) 
			{	string content = "<h2>Ошибка 404!!!</h1><br><h3>Запрашиваемый ресурс не найден!!!</h3>";
				string webpage = "HTTP/1.0 404 Not Found\r\n"
				~ "Content-Length: " ~ content.length.to!string ~ "\r\n"
				~ "Content-type: text/html; charset=\"utf-8\"\r\n\r\n"
				~ content;
				_socket.sendTo(webpage);
				finalize();
				return;
			}
			
			//Определяем длину тела запроса
			size_t contentLength = 0;
			if( headers["content-length"] !is null )
			{	try {
					contentLength = headers["content-length"].to!size_t;
				} catch(Exception e) { contentLength = 0; }
			}
			
			string messageBody;
			char[] bodyBuf;
			size_t extraBytesInHeaderBuf = headerBuf.length - headers.strLength;
			//Нужно определить сколько ещё нужно прочитать
			if( contentLength > extraBytesInHeaderBuf )
			{	bodyBuf.length = contentLength - extraBytesInHeaderBuf;
				_socket.receive(bodyBuf);
				messageBody = headers.extraData ~ bodyBuf.idup;
			}
			else
			{	messageBody = headers.extraData[0..contentLength];
			}
			
			
			//Загоняем данные в объект Application
			auto app = new Application( _handlerFunctions[path] );
			app.request = new Request( headers, messageBody );
			app.response = new Response( &this.write );
// 			writeln("Перед app.run();");
			app.run(); //Запускаем объект
// 			writeln("Перед app.finalize();");
			app.finalize(); //Завершаем объект
// 			writeln("После app.finalize();");
			finalize();
		}
		
		void finalize()
		{	_socket.shutdown(SocketShutdown.BOTH);
			_socket.close();
			_socket.destroy();
		}
	}
		
protected:
	static handlerFuncType[string] _handlerFunctions;
	Socket _socket;
}


