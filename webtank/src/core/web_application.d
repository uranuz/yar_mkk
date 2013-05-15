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
		
	string[string] POST() @property
	{	if( _POST.length <= 0 )
			_POST = extractURIData( _getStdInput() );
		return _POST;
	}
	
	string[string] GET() @property
	{	import std.process;
		if( _GET.length <= 0 )
			_GET = extractURIData( getenv("QUERY_STRING") );
		return _GET;
	}
	
protected:
	string _getStdInput()
	{	import std.stdio;
		string result;
		string buf;
		while ((buf = stdin.readln()) !is null)
			result ~= buf;
		return result;
	}
}

class Response  //Ответ приложения
{
protected:
	string _respBody = "";
	string[] _headers;
	Cookies _cookies; //Куки в ответ
public:
	this()
	{	_cookies = new Cookies; 
	}
	void write(string str)
	{	_respBody ~= str; }
	
	void opOpAssign(string op: "~")(string str)
	{	_respBody ~= str; }
	
	void redirect(string location)
	{	addHeader("Status: 302 Found");
		addHeader("Location: " ~ location);
	}
	
	void addHeader(string header)
	{	_headers ~= header; }
	
	void _submit()
	{	import std.stdio;
		string responseStr = _getHeaderStr() ~ _respBody;
		std.stdio.write( responseStr );
	}
	
	Cookies cookies() @property
	{ return _cookies; }

protected:
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