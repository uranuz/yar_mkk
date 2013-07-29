module webtank.net.application; 

import webtank.net.request, webtank.net.response;

class Application
{
public:
	alias void function(Application) handlerFuncType;
	
	this( handlerFuncType appMain )
	{	_appMain = appMain; 
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
	void _finalize()
	{	response.flush();
	}
	Request request;
	Response response;
	
	static void setHandler(handlerFuncType connHandler, string path)
	{	if( path in _handlerFunctions )
			assert(0, "Обработчик для пути: '" ~ path ~ "' уже зарегистрирован!!!");
		else
			_handlerFunctions[path] = connHandler;
	}
	
	static handlerFuncType getHandler(string path)
	{	return _handlerFunctions.get( path, null );
	}
protected:
	handlerFuncType _appMain;
	static handlerFuncType[string] _handlerFunctions;
}