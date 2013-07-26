module webtank.net.request;

import webtank.net.cookies;
import webtank.net.uri;

class Request  //Запрос к нашему приложению
{	
protected:
	RequestCookies _cookies; //Куки из запроса
	string[string] _POST;
	string[string] _GET;
	string _stdInputStr;
	
	string[][string] _POSTArray;
	string[][string] _GETArray;
public:
	this()
	{	_cookies = getCookies(); 
		import std.process;
		referer = getenv("HTTP_REFERER");
		host = getenv("HTTP_HOST");
		userAgent = getenv("HTTP_HOST");
	}
	
	//Получение кукев из запроса (сюда записывать нельзя)
	RequestCookies cookies() @property
	{	return _cookies; }
		
	//Данные переданные через стандартный ввод (методом POST)
	string[string] postVars() @property
	{	if( _POST.length <= 0 )
			_POST = extractURIData( _getStdInput() );
		return _POST;
	}
	
	string[][string] postVarsArray() @property
	{	if( _POSTArray.length <= 0 )
			_POSTArray = extractURIDataArray( _getStdInput() );
		return _POSTArray;
	}
	
	//Некоторые данные из HTTP-заголовков запроса к приложению
	immutable(string) referer;
	immutable(string) host;
	immutable(string) userAgent;
	
	//Данные из URI строки запроса
	string[string] queryVars() @property
	{	import std.process;
		if( _GET.length <= 0 )
			_GET = extractURIData( getenv("QUERY_STRING") );
		return _GET;
	}
	
	string[][string] queryVarsArray() @property
	{	import std.process;
		if( _GETArray.length <= 0 )
			_GETArray = extractURIDataArray( getenv("QUERY_STRING") );
		return _GETArray;
	}
	
protected:
	string _getStdInput()
	{	import std.stdio;
		if( _stdInputStr is null )
		{	string buf;
			while ((buf = stdin.readln()) !is null)
				_stdInputStr ~= buf;
		}
		return _stdInputStr;
	}
} 
