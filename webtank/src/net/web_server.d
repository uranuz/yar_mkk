import std.socket, std.string, std.conv, std.stdio, core.thread;

import webtank.net.application, webtank.net.http_headers, webtank.net.uri,
webtank.net.request, webtank.net.response;

class WorkingThread: Thread
{	
	this(Socket socket)
	{	_socket = socket;
		super(&_run);
	}
	
protected:
	Socket _socket;
	void _run()
	{	scope(exit) finalize(); //Завершение потока при выходе из _run
		size_t bytesRead;
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
		
		auto handler = Application.getHandler(path); //Получаем обработчик для пути
		if( handler is null ) 
		{	string content = "<h2>Ошибка 404!!!</h1><br><h3>Запрашиваемый ресурс не найден!!!</h3>";
			string webpage = "HTTP/1.0 404 Not Found\r\n"
			~ "Content-Length: " ~ content.length.to!string ~ "\r\n"
			~ "Content-type: text/html; charset=\"utf-8\"\r\n\r\n"
			~ content;
			_socket.sendTo(webpage);
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
		auto app = new Application( handler );
		app.request = new Request( headers, messageBody );
		app.response = new Response( &this.write );
		
		app.run(); //Запускаем объект
		scope(exit) app.finalize(); //Завершаем объект
	}
	
	//Выводит данные в сокет
	void write(string message)
	{	_socket.sendTo(message);
	}
	
	void finalize()
	{	_socket.shutdown(SocketShutdown.BOTH);
		_socket.close();
		_socket.destroy();
	}
	
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

	ushort port = 8082;
	
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

