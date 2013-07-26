import std.socket, std.string, std.conv, std.stdio, std.datetime, /*std.concurrency,*/ core.thread;

// class TimeoutException: Exception
// {	
// 	
// }

class WorkingThread: Thread
{
public:
	this(Socket socket)
	{	_sock = socket;
		super(&_run);
	};
	
	
	
	SysTime startTime() @property
	{	return _startTime; }

private:
	Socket _sock;

	string _content;
	string[string] _headerAttributes;
	SysTime _startTime;  //Время запуска нити исполнения
	
	void _run()
	{	_startTime = Clock.currTime(); //Определяем время запуска нити исполнения
		_processRequest();  
	}
	
	void _processHeaders()
	{	size_t bytesRead;
		char[] headerBuf;
		headerBuf.length = 1024;
		
		//Читаем из сокета в буфер
		bytesRead = _sock.receive(headerBuf);
		//TODO: Проверить сколько байт прочитано
// 		import std.stdio;
// 		writeln(cast(ubyte[]) headerBuf);
		
		string headerFirstLine; //Первая строка HTTP заголовка
		size_t i = 0;
		
		for( ; i < headerBuf.length; i++  )
		{	if( i+2 < headerBuf.length )
			{	if( headerBuf[i..i+2] == "\r\n" )
				{	headerFirstLine = headerBuf[0..i].idup;
					break;
				}
			}
		}
		
		import std.array;
		auto headerFirstLineAttr = split(headerFirstLine, " ");
		if( headerFirstLineAttr.length == 3 )
		{
			_headerAttributes["HTTP_METHOD"] = headerFirstLineAttr[0];
			_headerAttributes["HTTP_PATH"] = headerFirstLineAttr[1];
			_headerAttributes["HTTP_VERSION"] = headerFirstLineAttr[2];
		}
		else
		{	//TODO: Добавить ошибку, по стандарту должно быть 3 элемента
		}
		
		size_t headerStartPos = i + 2;
		size_t headerLength = headerBuf.length;
		
		//Отделяем строку с заголовками
		for( ; i < headerBuf.length; i++  )
		{	if( i+4 < headerBuf.length )
			{	if( headerBuf[i..i+4] == "\r\n\r\n" )
				{	headerLength = i;
					break;
				}
			}
		}
		if( (headerLength == 0) || (headerStartPos >= headerLength)  ) return;
		
		string[] headerAttrLines = split(headerBuf[headerStartPos..headerLength].idup, "\r\n");
		//Разбор заголовков
		foreach(var; headerAttrLines)
		{	for( size_t j = 0; j < var.length; j++ )
			{	if( j+2 < var.length )
				{	if( var[j..j+2] == ": " )
					{	_headerAttributes[ var[0..j] ] = var[j+2..$];
						break;
					}
				}
			}
		}
// 		import std.stdio;
// 		writeln(_headerAttributes);
	}
	
	string getMimeByExt(string fileName)
	{	import std.path;
		string fileExt = std.path.extension(fileName);
		
		string[][string] mimeExts = 
		[	"image/jpeg": [".jpg", ".jpeg"],
			"image/gif": [".gif"],
			"image/png": [".png"],
			"text/html": [".htm", ".html"],
			"text/plain": [".txt", ".d", ".log"],
			"text/css": [".css"],
			"application/javascript": [".js"]
		];
		foreach( mime, exts; mimeExts )
		{	foreach( ext; exts )
			{	if( fileExt == ext ) 
					return mime;
			}
		}
		return "text/plain";
	}
	
	void _processRequest()
	{	
		_processHeaders();
		
		import std.file, std.stdio;
		string fileRootDir = "/home/test_serv/sites/test/www";
		
		
		string fullFileName = fileRootDir ~ _headerAttributes["HTTP_PATH"];
		string fileContent;
		string MIMEType = "text/html";
		string HTTPStatus = "200 OK";
// 		
// 		if( std.file.exists(fullFileName) )
// 		{	if( std.file.isFile(fullFileName) )
// 			{	MIMEType = getMimeByExt(fullFileName);
// 				
// 				fileContent = cast(string) std.file.read(fullFileName);
// 				
// 			}
// 		}
// 		else HTTPStatus = "404 Not Found";

// 		_content = fileContent;

		_content = "<html><head>"
		~ `<meta name="google-site-verification" content="_zeDp8DaxCac1bXRAc2NPmVNNWhO5z0Yrfzs70QLITE" />`
		~ `<meta name='yandex-verification' content='4173c2c1fae1a68c' />`
		~ "</head><body><table border=1><tr><th>Имя</th><th>Значение</th></tr>";
// 		_content ~= "<tr><td>HTTP_METHOD</td><td>" ~ HTTPMethod ~ "</td></tr>";
// 		_content ~= "<tr><td>URI_PATH</td><td>" ~ URIPath ~ "</td></tr>";
// 		_content ~= "<tr><td>HTTP_VER</td><td>" ~ HTTPVersionStr ~ "</td></tr>";
		foreach( key, val; _headerAttributes)
		{	_content ~= "<tr><td>" ~ key ~ "</td><td>" ~ val ~ "</td></tr>";
		}
		_content ~= "</body></html>";
		
		if( HTTPStatus == "404 Not Found" )
		{	_content = "<html><body><h2>Ресурс не найден</h2></body></html>";
			MIMEType = "text/html";
		}
		
		string webpage = 
		"HTTP/1.1 " ~ HTTPStatus ~"\r\n"
		"Content-Length: " ~ _content.length.to!string 
		~ "\r\nContent-Type: " ~ MIMEType ~ "; charset=UTF-8\r\n\r\n" 
		~ _content;
		
		_sock.sendTo(webpage);
		
		
// 		writeln(bytesRead);
		_sock.shutdown(SocketShutdown.BOTH);
		_sock.close();
		_sock.destroy();
	}

}

class ListenningThread: Thread
{	
	this(std.socket.Address addr, ThreadManager threadManager)
	{	super(&_listen);
		_address = addr;
		_threadManager = threadManager;
	};
	

protected:
	std.socket.Address _address;
	ThreadManager _threadManager;

	void _listen()
	{	Socket listener = new TcpSocket;
		scope(exit) 
		{	listener.shutdown(SocketShutdown.BOTH);
			listener.close();
		}
		assert(listener.isAlive);
		listener.bind(_address);
		listener.listen(1);
		
		while(true) 
		{	if(_threadManager.isStopped) return; //Завершение приёма соединений
		
			while( _threadManager.isPaused )  //Приостанавливаем прием соединений
				this.sleep( dur!("seconds")( 3 ) );
			
			Socket currSock = listener.accept(); //Принимаем соединение
			_threadManager.startThread( new WorkingThread(currSock) );
		}
	}
}


immutable workingThreadLimit = 150;

class ThreadManager: Thread
{	
	this()
	{	super(&_watch);
	};
	
	void startThread(WorkingThread workThread)
	{	synchronized (this) 
		{	if( (_workingThreads.length < workingThreadLimit) && !_isPaused && !_isStopped ) //Проверяем предельное число потоков
			{	_workingThreads ~= workThread;
				workThread.start();
			}
		}
	}
	
	void pause()
	{	synchronized(this)
			_isPaused = true;
	}
	
	void resume()
	{	synchronized(this)
			_isPaused = false;
	}
	
	bool isPaused() @property
	{	synchronized(this)
			return _isPaused;
	}
	
	void stop()
	{	synchronized(this)
			_isStopped = true;
	}
	
	bool isStopped() @property
	{	synchronized(this)
			return _isStopped;
	}
	
protected:
	WorkingThread[] _workingThreads;
	bool _isPaused = false; //Обрабатываем соединения или нет?
	bool _isStopped = false;
	
	void _watch()
	{		
		while(1) 
		{	if(_isStopped)
			{	//Присоединяем все потоки
				//Выходим из функции
				foreach( th; _workingThreads )
					th.join();
				return; //Останов обработки
			}
			this.sleep( dur!("seconds")( 5 ) );
		
			WorkingThread[] updatedWorkingThreads;
			foreach( th; _workingThreads )
			{	if( th.isRunning() )
				{	_workingThreads ~= th;
				}
			}
			_workingThreads.length = 0;
			_workingThreads = updatedWorkingThreads;
		}
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

	auto thManager = new ThreadManager;
	thManager.start();
	scope(exit) thManager.join();
	
	ushort port = 8085;
	
	auto listenThread = new ListenningThread( new InternetAddress(port), thManager );
	listenThread.isDaemon = true;
	listenThread.start();
// 	scope(exit) listenThread.join();
	
	
	while(true)
	{	
		string buf = readln();
		if( buf == "pause\n" )
		{	writeln("Приостанавливаем обработку соединений");
			thManager.pause() ;
		}
		else if( buf == "resume\n" )
		{	writeln("Запускаем обработку соединений");
			thManager.resume();
		}
		else if( buf == "stop\n" )
		{	writeln("Останавливаем сервер");
			thManager.stop();
			return;
		}
		//Закрываем потоки
		//Блокируем запуск новых рабочих потоков
		//Посылаем сообщения старым рабочим потокам о закрытии
		//Посылаем сообщения служебным потокам о закрытии
	}
}

