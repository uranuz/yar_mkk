module webtank.net.response;

import webtank.net.cookies;
import webtank.net.uri;

class Response  //Ответ от нашего приложения
{
protected:
	string _respBody = "";
	string[] _headers;
	ResponseCookies _cookies; //Куки в ответ
public:
	this( void delegate(string) write )
	{	_cookies = new ResponseCookies; 
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
	{	addHeader("Status: 302 Found");
		addHeader("Location: " ~ location);
	}
	
	//Добавление HTTP-заголовка в ответ приложения
	void addHeader(string header)
	{	_headers ~= header; }
	
	void flush()
	{	if( !_headersSent ) 
		{	_headersSent = true;
			_write( _getHeaderStr() );
		}
		_write( _respBody );
	}
	
	//Куки ответа приложения (в них только пишем)
	ResponseCookies cookies() @property
	{	return _cookies; }

protected:
	void delegate(string) _write;
	bool _headersSent = false;
	
	string _getCustomHeaderStr()
	{	string result;
		foreach(header; _headers)
			result ~= header ~ "\r\n";
		return result;
	}
	
	string _getHeaderStr()
	{	return 
			_getCustomHeaderStr()
			~ _cookies.getResponseStr() 
			~ "Content-type: text/html; charset=\"utf-8\" \r\n\r\n"; 
	}
}