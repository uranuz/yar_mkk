import std.socket, std.string, std.conv, core.thread, std.stdio;

import webtank.net.application, webtank.net.http_headers, webtank.net.uri,
webtank.net.request, webtank.net.response;

immutable(size_t) startBufLength = 1024;
immutable(size_t) messageBodyLimit = 4_194_304;

class WorkingThread: Thread
{	
	this(Socket socket)
	{	_socket = socket;
		super(&_run);
	}
	
protected:
	Socket _socket;
	void _run()
	{	scope(exit) _finalize(); //Завершение потока при выходе из _run
		size_t bytesRead;
		char[] startBuf;
		startBuf.length = startBufLength;
		
		//Читаем из сокета в буфер
		bytesRead = _socket.receive(startBuf);
		//TODO: Проверить сколько байт прочитано
		
		auto headers = new HTTPHeaders(startBuf.idup);
		
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
		scope(exit) app.finalize(); //Завершаем объект
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

enum string[2][ushort] HTTPStatusInfo =
[	400: ["Bad Request", "Некорректный запрос к серверу"],
	401: ["Unauthorized", "Не авторизован"],
	403: ["Forbidden", "Доступ запрещён"],
	404: ["Not Found", "Запрашиваемый ресурс не найден"],
	413: ["Request Entity Too Large", "Размер тела запроса слишком велик"],
	
	
	500: ["Internal Server Error", "Внутренняя ошибка сервера"],
	505: ["HTTP Version Not Supported", "Версия протокола HTTP не поддерживается"]
];

string generateServicePage(ushort statusCode)
{	import std.conv;

	string content = "<html><body><h3>Код " ~ statusCode.to!string 
	~ ". " ~ HTTPStatusInfo[statusCode][1] ~ "</h3>"
	~`<hr><p style="text-align: right;">webtank.net.web_server</p></body></html>`;
	
	return 
	"HTTP/1.0 " ~ statusCode.to!string ~ " " 
	~ HTTPStatusInfo[statusCode][0] ~ "\r\n"
	~ "Content-Length: " ~ content.length.to!string ~ "\r\n"
	~ "Content-type: text/html; charset=\"utf-8\"\r\n\r\n"
	~ content;
}



void main() {
	//Основной поток - поток управления потоками
	
	/**
	Какие нужны в принципе потоки, если исходить из работы на потоках?
	 - Нужен слушающий поток, который будет прослушивать порт на предмет входящих соединений
	   и запускать рабочие потоки
	 - Нужны рабочие потоки, которые будут обрабатывать запросы пользователей и отвечать им
	 - Нужен поток мониторинга рабочих потоков, который будет следить за их состоянием
	 - Можно выделить поток логирования (или даже в отдельный процесс)
	 - Можно выделить поток загрузки ресурсов, кэширования и управления кэшем ресурсов
	
	Вопрос: что из этого, возможно, лучше выделить в отдельные процессы для простоты или надежности?
	*/

	ushort port = 8083;
	
	Socket listener = new TcpSocket;
	scope(exit) 
	{	listener.shutdown(SocketShutdown.BOTH);
		listener.close();
	}
	assert(listener.isAlive);
	listener.bind( new InternetAddress(port) );
	listener.listen(1);
	
	while(true)
	{	Socket currSock = listener.accept(); //Принимаем соединение
		auto workingThread = new WorkingThread(currSock);
		workingThread.start();
	}
}

