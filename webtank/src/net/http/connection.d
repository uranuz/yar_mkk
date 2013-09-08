module webtank.net.http.connection;

import std.socket;

immutable(size_t) startBufLength = 1024;
immutable(size_t) messageBodyLimit = 4_194_304;

//Класс работающий с сетевым соединением по протоколу HTTP
class ServerConnection
{	
protected:
	Socket _socket;
	http.ServerRequest _request;
	http.ServerResponse _response;
	char[] _requestBuffer;
	
public:
	this( Socket s )
	{	_socket = s;
		
	}
	
	//Свойство формирует экземпляр запроса к серверу
	http.ServerRequest request() @property
	{	if( _request is null )
			receiveRequest();
		return _request;
	}
	
	//Свойство формирует экземпляр класса для формирования
	//ответа сервера на запрос
	http.ServerResponse response() @property
	{	if( _response is null )
			_response = new http.ServerResponse;
	}
	
	void sendResponse()
	{
		
	}
	
	http.RequestHeaders receiveRequestHeaders()
	{	/+scope(exit) _finalize(); //Завершение потока при выходе из _run+/
		size_t bytesRead;
		char[] startBuf;
		startBuf.length = startBufLength;
		
		//Читаем из сокета в буфер
		bytesRead = _socket.receive(startBuf);
		//TODO: Проверить сколько байт прочитано
		
		auto headers = new RequestHeaders(startBuf.idup);
		
		return headers;
	}
	
	void sendResponseHeaders()
	{	
		
	}
	
	void receiveRequest()
	{	auto headers = receiveRequestHeaders();
		
		if( headers.errorCode != 0 )
		{	/+_socket.sendTo( generateServicePage(headers.errorCode) );+/
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
		{	/+_socket.sendTo( generateServicePage(413) );+/
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
		
		_request = new ServerRequest( headers, messageBody );
	}
	
	//Выводит данные в сокет
	void send(string message)
	{	_socket.sendTo(message);
	}
	
	void _finalize()
	{	_socket.shutdown(SocketShutdown.BOTH);
		_socket.close();
		_socket.destroy();
	}
	
	
}