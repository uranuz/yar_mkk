module webtank.net.web_server;

import std.socket, std.string, std.conv, core.thread, std.stdio, std.datetime, std.getopt;

import webtank.net.http.http_routing, webtank.net.routing;

class WebServer
{	
protected:
	ushort _port = 8082;
	
public:
	this(ushort port) { _port = port;}
	
	void start()
	{	Socket listener = new TcpSocket;
		scope(exit) 
		{	listener.shutdown(SocketShutdown.BOTH);
			listener.close();
		}
		assert(listener.isAlive);
		
		bool isNotBinded = true;
		writeln("Пытаемся привязать серверный сокет к порту " ~ _port.to!string );
		while( isNotBinded )  //Заставляем ОСь дать нам порт
		{	try {
				listener.bind( new InternetAddress(_port) );
				isNotBinded = false;
			} catch(std.socket.SocketOSException) {}
		}
		listener.listen(1);
		writeln("Сайт стартовал!");
		
		while(true) //Цикл приёма соединений через серверный сокет
		{	Socket currSock = listener.accept(); //Принимаем соединение
			auto workingThread = new WorkingThread(currSock);
			workingThread.start();
		}
		
	}
}

import std.socket, std.conv;

import webtank.net.http.request, webtank.net.http.response, webtank.net.http.headers;

immutable(size_t) startBufLength = 1024;
immutable(size_t) messageBodyLimit = 4_194_304;

//Функция принимает запрос из сокета и возвращает экземпляр ServerRequest
//или кидается исключениями при ошибках
ServerRequest receiveHTTPRequest(Socket sock)
{	
// 	size_t bytesRead;
	char[] startBuf;
	startBuf.length = startBufLength;
	
	//Читаем из сокета в буфер
// 	bytesRead = 
	sock.receive(startBuf);
	//TODO: Проверить сколько байт прочитано
	
	auto headers = new RequestHeaders(startBuf.idup);
	
	if( headers.errorCode != 0 )
	{	/+sock.sendTo( generateServicePage(headers.errorCode) );+/
		//TODO: Исправить на генерацию осмысленных исключений,
		//их обработку и создание запроса маршрутизатору на страницу с ошибкой
		return null;
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
	{	/+sock.sendTo( generateServicePage(413) );+/
		//TODO: Аналогично предыдущему
		return null;
	}
	
// 		write("headers.strLength: "); writeln( headers.strLength );
	
	string messageBody;
	char[] bodyBuf;
	size_t extraBytesInHeaderBuf = startBufLength - headers.strLength;
// 		write("extraBytesInHeaderBuf: "); writeln( extraBytesInHeaderBuf );
	//Нужно определить сколько ещё нужно прочитать
	if( contentLength > extraBytesInHeaderBuf )
	{	bodyBuf.length = contentLength - extraBytesInHeaderBuf;
		sock.receive(bodyBuf);
		messageBody = headers.extraData ~ bodyBuf.idup;
// 			writeln("contentLength > extraBytesInHeaderBuf");
	}
	else
	{	messageBody = headers.extraData[0..contentLength];
// 			writeln("contentLength < extraBytesInHeaderBuf");
	}
// 		write("messageBody.length: "); writeln( messageBody.length ); 
	
	return new ServerRequest( headers, messageBody );
}


//Рабочий процесс веб-сервера
class WorkingThread: Thread
{	
protected:
	Socket _socket;
	
public:
	this(Socket sock)
	{	_socket = sock;
		super(&_work);
	}
	
protected:
	void _work()
	{	auto request = receiveHTTPRequest(_socket);
		
		//TODO: Исправить на передачу запроса на страницу
		//с ошибкой маршрутизатору, а не просто падение сервера
		if( request is null )
			return; 
		
		auto response = new ServerResponse(&_socket.writeTo);
		auto context = new HTTPContext(request, response);
		
		//Запуск обработки HTTP-запроса через маршрутизатор
		router.process( context );
		scope(exit) 
		{	_socket.shutdown(SocketShutdown.BOTH);
			_socket.close();
		}
	}
}

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	ushort port = 8082;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );
	
	
	//TODO: Исправить это временное решение
	//Отстраиваем дерево маршрутизации
	buildRoutingTree();
	
	auto server = new WebServer(port);
	server.start();
}

