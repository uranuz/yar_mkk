module webtank.net.connection_handler;

import std.conv;

import webtank.net.application, webtank.net.uri, webtank.net.http_headers;

IConnectionHandler connectionHandler;

alias void function(Application) handlerFuncType;

interface IConnectionHandler
{	
	void setHandler(handlerFuncType connHandler, string path);
	void write(string message);
	void run();
	void finalize();
}

class HTTPConnectionHandler: IConnectionHandler
{	
	import std.socket;
	this(Socket socket)
	{	_socket = socket;
		connectionHandler = this;
	}

	override {
		void setHandler(handlerFuncType connHandler, string path)
		{	if( path in _handlerFunctions )
				assert(0, "Обработчик для пути: '" ~ path ~ "' уже зарегистрирован!!!");
			else
				_handlerFunctions[path] = connHandler;
		}
		
		//Выводит данные в сокет
		void write(string message)
		{	_socket.sendTo(message):
		}
		
		void run()
		{	size_t bytesRead;
			char[] headerBuf;
			headerBuf.length = 1024;
			
			//Читаем из сокета в буфер
			bytesRead = _sock.receive(headerBuf);
			//TODO: Проверить сколько байт прочитано
			
			auto headers = new HTTPHeaders(headerBuf.idup);
			
			string path;
			if( headers["request-uri"] !is null )
			{	path = separatePath( headers["request-uri"] );
			}
			
			if( path !in _handlerFunctions ) return;
			
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
				_sock.receive(bodyBuf);
				messageBody = headers.extraData ~ bodyBuf.idup;
			}
			else
			{	messageBody = headers.extraData[0..contentLength];
			}
			
			
			//Загоняем данные в объект Application
			auto app = new Application( _handlerFunctions[path] );
			app.request = new Request( headers, messageBody );
			app.response = new Response( &this.write );
			
			app.run(); //Запускаем объект
			app.finalize(); //Завершаем объект
		}
		
		void finalize()
		{	_socket.shutdown(SocketShutdown.BOTH);
			_socket.close();
			_socket.destroy();
		}
	}
		
protected:
	immutable(handlerFuncType[string]) _handlerFunctions;
	Socket _socket;
}


