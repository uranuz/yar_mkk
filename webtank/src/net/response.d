module webtank.net.response;

import webtank.net.http_cookie, webtank.net.uri, webtank.net.http_headers;

class Response  //Ответ от нашего приложения
{
	ResponseHeaders headers;
protected:
	string _respBody;
	ResponseCookie _cookie; //Куки в ответ
public:
	

	this( void delegate(string) write )
	{	_cookie = new ResponseCookie;
		headers = new ResponseHeaders;
		_write = write;
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
	
	void flush()
	{	if( !_headersSent ) 
		{	_headersSent = true;
			_write( _getHeaderStr() );
		}
		_write( _respBody );
	}
	
	//Пытаемся очистить ответ, возвращает true, если получилось
	bool tryClear()
	{	if( !_headersSent )
		{	_respBody = null;
			headers.clear();
			_cookie.clear();
			return true;
		}
		return false;
	}
	
	//Куки ответа приложения (в них только пишем)
	ResponseCookie cookie() @property
	{	return _cookie; }

protected:
	void delegate(string) _write;
	bool _headersSent = false;
	
	string _getHeaderStr()
	{	import std.conv;
		headers["content-length"] = std.conv.to!string(_respBody.length);
// 		if( _cookie.length > 0 )
// 			headers["set-cookie"] = _cookie.getString();
		headers["content-type"] = "text/html; charset=\"utf-8\"";
		return 
		headers.getStatusLine() 
		~ _cookie.getString() 
		~ headers.getString() ~ "\r\n" ;
	}
}