import std.socket, std.string, std.conv, std.stdio, /*std.concurrency,*/ core.thread;

class WorkingThread: Thread
{
public:
	this(Socket socket)
	{	_sock = socket;
		super(&processRequest);
	};
	
	void run()
	{	this.start();
	}

private:
	Socket _sock;

	string _content;
	string[string] _headerAttributes;
	
	
	void processHeaders()
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
	
	void processRequest()
	{	
		processHeaders();
		
		import std.file, std.stdio;
		string fileRootDir = "/home/test_serv/sites/test/www";
		
		
		string fullFileName = fileRootDir ~ _headerAttributes["HTTP_PATH"];
		string fileContent;
		string MIMEType;
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

		_content = "<html><body><table border=1><tr><th>Имя</th><th>Значение</th></tr>";
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
	
void main() {
	
	ushort port = 8082;
	auto address = new InternetAddress(port);
	Socket listener = new TcpSocket;
	assert(listener.isAlive);
	listener.bind(address);
	listener.listen(1);
	
// 	WorkingThread[] threads;

	while(1) 
	{	
		
		Socket currSock = listener.accept();
		auto th = new WorkingThread(currSock);
// 		threads ~= new WorkingThread(/+currSock+/);
		th.run();
// 		threads[$-1].run();
		
// 		if( threads.length >= 20 )
// 		{	for( size_t i = 0; i < 20; i++)
// 			{	threads[i].join();
// 				delete threads[i];
// 			}
// 			threads.length = 0;
// 		}
		
// 		listener.shutdown(SocketShutdown.BOTH);		
	}
}

