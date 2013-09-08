module webtank.net.web_server;

import std.socket, std.string, std.conv, core.thread, std.stdio, std.datetime, std.getopt;

import webtank.net.http.connection, webtank.net.http.router;

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
		
		listener.bind( new InternetAddress(_port) );
		listener.listen(5);
		writeln("Сайт стартовал!");
		
		while(true)
		{	Socket currSock = listener.accept(); //Принимаем соединение
			auto workingThread = new WorkingThread(currSock);
			workingThread.start();
		}
		
	}
}

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
	{	auto conn = new http.Connection(_socket);
		http.Router.getRPCMethod
		
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

