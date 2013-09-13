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
	{	auto conn = new ServerConnection(_socket);
		Router.processRequest(conn.request, conn.response);
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

