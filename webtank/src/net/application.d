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
			string errorMessage = std.string.translate( exception.toString(), ['\n': "<br>\r\n"] );
			if( response.tryClear() )
			{	response.headers["http-version"] = "HTTP/1.0";
				response.headers["status-code"] = "500";
				response.headers["reason-phrase"] = "Internal Server Error";
				
				response ~= generateServicePageContent(500, errorMessage);
			}
			else
				response ~= errorMessage;
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


enum string[2][ushort] HTTPStatusInfo =
[	400: ["Bad Request", "Некорректный запрос к серверу"],
	401: ["Unauthorized", "Не авторизован"],
	403: ["Forbidden", "Доступ запрещён"],
	404: ["Not Found", "Запрашиваемый ресурс не найден"],
	413: ["Request Entity Too Large", "Размер тела запроса слишком велик"],
	
	500: ["Internal Server Error", "Внутренняя ошибка сервера"],
	501: ["Not Implemented", "Метод не поддерживается сервером"],
	505: ["HTTP Version Not Supported", "Версия протокола HTTP не поддерживается"]
];

string generateServicePage(ushort statusCode, string info = null)
{	import std.conv;
	string content = generateServicePageContent(statusCode, info);
	
	return 
	"HTTP/1.0 " ~ std.conv.to!string(statusCode) ~ " " 
	~ HTTPStatusInfo[statusCode][0] ~ "\r\n"
	~ "Content-Length: " ~ std.conv.to!string(content.length) ~ "\r\n"
	~ "Content-type: text/html; charset=\"utf-8\"\r\n\r\n"
	~ content;
}

string generateServicePageContent(ushort statusCode, string info = null)
{	import std.conv;
	return 
	( `<html><body><h3>Код ` ~ std.conv.to!string(statusCode)
	~ ". " ~ HTTPStatusInfo[statusCode][1] ~ "</h3>\r\n" 
	~ ( ( info.length > 0 ) ? (info ~ "\r\n") : "" )
	~`<hr><p style="text-align: right;">webtank.net.web_server</p></body></html>` );
}