module webtank.core.web_application; 

import webtank.core.cookies;

import std.process;


class Request  //Запрос к приложению
{	
protected:
	Cookies _cookies; //Куки из запроса
public:
	this()
	{	_cookies = new Cookies( getenv(`HTTP_COOKIE`) ); //Актуально для Apache
	}
	Cookies cookies() @property
	{	return _cookies; }
}

class Response  //Ответ приложения
{
protected:
	string _respBody = "";
	Cookies _cookies; //Куки в ответ
public:
	this()
	{	_cookies = new Cookies; 
	}
	void write(string str)
	{	_respBody ~= str; }
	
	void _submit()
	{	import std.stdio;
		string responseStr = _getHeaderStr() ~ _respBody;
		std.stdio.write( responseStr );
	}
	
	string _getHeaderStr()
	{	return 
			_cookies.getResponseStr() 
			~ "Content-type: text/html; charset=\"utf-8\" \r\n\r\n"; 
	}
	
	Cookies cookies() @property
	{ return _cookies; }
}

class WebApplication
{
public:
	alias void function(WebApplication) AppMainT;
protected:
	AppMainT _appMain;
	string _output;
public:
	this( AppMainT appMain )
	{	_appMain = appMain; 
		response = new Response;
		request = new Request;
	}

	void run()  //Функция запуска приложения
	{	if( _appMain !is null)
			_appMain(this);
		//else //TODO: кинуть ошибку
	}
	void finalize()
	{	response._submit();
	}
	string name;
	Request request;
	Response response;
}