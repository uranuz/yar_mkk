module webtank.net.application; 

import webtank.common.log;
import webtank.net.cookies;
import webtank.net.uri;
import webtank.net.request;
import webtank.net.response;
import webtank.net.authentication;

class Application
{
public:
	alias void function(Application) AppMainT;
protected:
	AppMainT _appMain;
public:
	this( AppMainT appMain )
	{	_appMain = appMain; 
		response = new Response;
		request = new Request;
		auth = new Authentication;
		
		//Организуем логирование
		import std.stdio;
		auto errorLog = std.stdio.File("/home/test_serv/sites/test/logs/error.log", "a");
		auto eventLog = std.stdio.File("/home/test_serv/sites/test/logs/event.log", "a"); 
		log = new FileLogger(errorLog, eventLog, LogLevel.dbg);
	}

	void run()  //Функция запуска приложения
	{	try {
			log.dbg("Старт приложения", "Вход в Application._appMain");
			if( _appMain !is null)
				_appMain(this);
			//else //TODO: кинуть ошибку
		}
		catch (Throwable exception)
		{	import std.string;
			log.crit(
				"\r\n<hr>\r\n"
				"Обнаружена ошибка при работе сервера:<br>\r\n"
				"Сообщение об ошибке: <br>\r\n" 
				~ std.string.translate( exception.toString(), ['\n': "<br>\r\n"] ) ~ "\r\n"
			);
// 			response.write(
// 			"\r\n<hr>\r\n"
// 			"Обнаружена ошибка при работе сервера:<br>\r\n"
// 			"Сообщение об ошибке: <br>\r\n" 
// 			~ std.string.translate( exception.toString(), ['\n': "<br>\r\n"] ) ~ "\r\n"
// 			);
			
		}
	}
	void finalize()
	{	response._submit();
	}
	string name;
	Request request;
	Response response;
	Authentication auth;
	ILogger log;
}