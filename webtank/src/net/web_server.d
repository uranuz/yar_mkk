module webtank.net.web_server;

import std.socket, std.string, std.conv, core.thread, std.stdio, std.datetime, std.getopt;

import webtank.net.routing, webtank.net.http.context;

class WebServer
{	
protected:
	ushort _port = 8082;
	
public:
	this(ushort port) 
	{	_port = port;
		
		//TODO: Исправить это временное решение
		//Отстраиваем дерево маршрутизации
		Router.start();
	}
	
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
				
				//Ждём, чтобы излишне не загружать систему
				Thread.sleep( dur!("msecs")( 500 ) ); 
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
	
	auto headersParser = new HTTPHeadersParser(startBuf.idup);
	
	auto headers = headersParser.getHeaders();
	
	if( headers is null )
		throw new HTTPException(
			"Request headers buffer is too large or is empty or malformed!!!",
			400 //400 Bad Request
		);
	
	//Определяем длину тела запроса
	size_t contentLength = 0;
	if( headers["content-length"] !is null )
	{	try {
			contentLength = headers["content-length"].to!size_t;
		} catch(Exception e) { contentLength = 0; }
	}
	
	//Проверяем размер тела запроса
	if( contentLength > messageBodyLimit )
		throw new HTTPException(
			"Content length is too large!!!",
			413 //413 Request Entity Too Large
		);
	
	string messageBody;
	char[] bodyBuf;
	size_t extraBytesInHeaderBuf = startBufLength - headersParser.headerData.length;
	//Нужно определить сколько ещё нужно прочитать
	if( contentLength > extraBytesInHeaderBuf )
	{	bodyBuf.length = contentLength - extraBytesInHeaderBuf;
		sock.receive(bodyBuf);
		messageBody = headersParser.bodyData ~ bodyBuf.idup;
	}
	else
	{	messageBody = headersParser.bodyData[0..contentLength];
	}
	
	return new ServerRequest( headers, messageBody );
}

enum string[ushort] HTTPReasonPhrases = 
[	
	///1xx: Informational
	///1xx: Информационные — запрос получен, продолжается процесс
	100: "Continue", 101: "Switching Protocols", 102: "Processing",

	///2xx: Success
	///2xx: Успешные коды — действие было успешно получено, принято и обработано
	200: "OK", 201: "Created", 202: "Accepted", 203: "Non-Authoritative Information", 204: "No Content", 205: "Reset Content", 206: "Partial Content", 207: "Multi-Status", 226: "IM Used",
	
	///3xx: Redirection
	///3xx: Перенаправление — дальнейшие действия должны быть предприняты для того, чтобы выполнить запрос
	300: "Multiple Choices", 301: "Moved Permanently", 302: "Found", 303: "See Other", 304: "Not Modified", 305: "Use Proxy", 307: "Temporary Redirect",
	
	///4xx: Client Error 
	///4xx: Ошибка клиента — запрос имеет плохой синтаксис или не может быть выполнен
	400: "Bad Request", 401: "Unauthorized", 402: "Payment Required", 403: "Forbidden", 404: "Not Found", 405: "Method Not Allowed", 406: "Not Acceptable", 407: "Proxy Authentication Required", 408: "Request Timeout", 409: "Conflict", 410: "Gone", 411: "Length Required", 412: "Precondition Failed", 414: "Request-URL Too Long", 415: "Unsupported Media Type", 416: "Requested Range Not Satisfiable", 417: "Expectation Failed", 418: "I'm a teapot", 422: "Unprocessable Entity", 423: "Locked", 424: "Failed Dependency", 425: "Unordered Collection", 426: "Upgrade Required", 456: "Unrecoverable Error", 499: "Retry With", 
	
	///5xx: Server Error
	///5xx: Ошибка сервера — сервер не в состоянии выполнить допустимый запрос
	500: "Internal Server Error", 501: "Not Implemented", 502: "Bad Gateway", 503: "Service Unavailable", 504: "Gateway Timeout", 505: "HTTP Version Not Supported", 506: "Variant Also Negotiates", 507: "Insufficient Storage", 509: "Bandwidth Limit Exceeded", 510: "Not Extended"
];

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
	void socketSend(string msg)
	{	_socket.sendTo(msg);
	}

	void _work()
	{	
		
		ServerRequest request;
		
		try {
			request = receiveHTTPRequest(_socket);
		} catch( HTTPException exc ) {
			//TODO: Построить правильный запрос и отправить на обработку ошибок
// 			response.clear();
// 			string statusCodeStr = exc.HTTPStatusCode.to!string;
// 			string reasonPhrase = HTTPReasonPhrases.get(exc.HTTPStatusCode, "Absolutely unknown status");
// 			response.headers["status-code"] = statusCodeStr;
// 			response.headers["reason-phrase"] = reasonPhrase;
// 			response.write(
// 				`<html><head><title>` ~ statusCodeStr ~ ` ` ~ reasonPhrase ~ `</title></head><body>`
// 				~ `<h3>` ~ statusCodeStr ~ ` ` ~ reasonPhrase ~ `</h3>`
// 				~ `<h4>` ~ exc.msg ~ `</h4>`
// 				~ `<hr><p style="text-align: right;">webtank.net.web_server</p>`
// 				~ `</body></html>`
// 			);
			return;
		}
		//TODO: Исправить на передачу запроса на страницу
		//с ошибкой маршрутизатору, а не просто падение сервера
		if( request is null )
			return; 
		
		auto context = new HTTPContext( request, new ServerResponse(&socketSend) );
		
		//Запуск обработки HTTP-запроса через маршрутизатор
		Router.process( context );
		
		context.response.flush();
		
		Thread.sleep( dur!("msecs")( 300 ) );
		
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

	
	auto server = new WebServer(port);
	server.start();
}

