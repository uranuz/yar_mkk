module webtank.net.http.response;

import webtank.net.http.cookie, webtank.net.http.uri, webtank.net.http.headers;

class ServerResponse  //Ответ от нашего приложения
{
	HTTPHeaders headers;
protected:
	string _respBody;
	ResponseCookie _cookie; //Куки в ответ
public:
	
	this(/+ void delegate(string) send +/)
	{	_cookie = new ResponseCookie;
		headers = new HTTPHeaders;
// 		_send = send;
	}
	
	//Записывает данные в буфер для отдачи
	void write(string str)
	{	_respBody ~= str; }
	
	//То же самое, но в виде оператора приклеивания ~=
	void opOpAssign(string op: "~")(string str)
	{	_respBody ~= str; }
	
	//Перенаправление пользователя по указанному адресу
	void redirect(string location)
	{	headers["status-code"] = "302";
		headers["reason-phrase"] = "Found";
		headers["location"] = location;
	}

	//TODO: Разобраться с отправкой ответа клиенту
// 	void flush()
// 	{	if( !_headersSent ) 
// 		{	_headersSent = true;
// 			_send( _getHeaderStr() );
// 		}
// 		_send( _respBody );
// 	}
	
	string getString()
	{	return _getHeaderStr() ~ _respBody;
	}
	
	//Пытаемся очистить ответ, возвращает true, если получилось
// 	bool tryClear()
// 	{	if( !_headersSent )
// 		{	_respBody = null;
// 			headers.clear();
// 			_cookie.clear();
// 			return true;
// 		}
// 		return false;
// 	}
	
	//Куки ответа приложения (в них только пишем)
	ResponseCookie cookie() @property
	{	return _cookie; }

protected:
// 	void delegate(string) _send;
// 	bool _headersSent = false;
	
	string _getHeaderStr()
	{	import std.conv, std.stdio;
		headers["content-length"] = _respBody.length.to!string;
		writeln( headers["content-length"] );
// 		if( _cookie.length > 0 )
// 			headers["set-cookie"] = _cookie.getString();
		headers["content-type"] = "text/html; charset=\"utf-8\"";
		return 
		headers.getStatusLine() 
		~ _cookie.getString() 
		~ headers.getString() ~ "\r\n" ;
	}
}