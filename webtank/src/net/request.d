module webtank.core.http.request;

import webtank.core.http.cookies;
import webtank.core.http.uri;

class Request  //Запрос к приложению
{	
protected:
	Cookies _cookies; //Куки из запроса
	string[string] _POST;
	string[string] _GET;
	string _stdInputStr;
public:
	this()
	{	_cookies = getCookies(); 
		import std.process;
		referer = getenv("HTTP_REFERER");
		host = getenv("HTTP_HOST");
		userAgent = getenv("HTTP_HOST");
	}
	
	Cookies cookies() @property
	{	return _cookies; }
		
	string[string] POST() @property
	{	if( _POST.length <= 0 )
			_POST = extractURIData( _getStdInput() );
		return _POST;
	}
	
	immutable(string) referer;
	immutable(string) host;
	immutable(string) userAgent;
	
	string[string] GET() @property
	{	import std.process;
		if( _GET.length <= 0 )
			_GET = extractURIData( getenv("QUERY_STRING") );
		return _GET;
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
