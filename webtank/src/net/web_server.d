import std.socket, std.string, std.conv, std.stdio, core.thread;

import webtank.net.connection_handler;


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

	ushort port = 8085;
	
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
		_connHandler = new HTTPConnectionHandler(socket);
		auto th = new Thread(&_connHandler.run);
		th.isDaemon = true;
		th.start();
	}
}

