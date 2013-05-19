module webtank.net.application; 

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
	}

	void run()  //Функция запуска приложения
	{	try {
			if( _appMain !is null)
				_appMain(this);
			//else //TODO: кинуть ошибку
		}
		catch (Throwable exception)
		{	import std.string;
			response.write(
			"\r\n<hr>\r\n"
			"Обнаружена ошибка при работе сервера:<br>\r\n"
			"Сообщение об ошибке: <br>\r\n" 
			~ std.string.translate( exception.toString(), ['\n': "<br>\r\n"] ) ~ "\r\n"
			);
			
		}
	}
	void finalize()
	{	response._submit();
	}
	string name;
	Request request;
	Response response;
	Authentication auth;
}