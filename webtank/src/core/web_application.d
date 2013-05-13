module webtank.core.web_application; 

import webtank.core.cookies;
import webtank.core.authentication;
import webtank.core.uri;

class Request  //Запрос к приложению
{	
protected:
	Cookies _cookies; //Куки из запроса
	string[string] _POST;
	string[string] _GET;
public:
	this()
	{	_cookies = getCookies(); }
	Cookies cookies() @property
	{	return _cookies; }
	
	string getStdInput()
	{	import std.stdio;
		string result;
		string buf;
		while ((buf = stdin.readln()) !is null)
			result ~= buf;
		return result;
	}
	
	string[string] POST() @property
	{	if( _POST.length <= 0 )
			_POST = extractURIData( getStdInput() );
		return _POST;
	}
	
	string[string] GET() @property
	{	import std.process;
		if( _GET.length <= 0 )
			_GET = extractURIData( getenv("QUERY_STRING") );
		return _GET;
	}
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
public:
	this( AppMainT appMain )
	{	_appMain = appMain; 
		response = new Response;
		request = new Request;
		auth = new Authentication;
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
	Authentication auth;
}