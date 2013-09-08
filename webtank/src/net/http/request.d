module webtank.net.http.request;

import webtank.net.http.cookie, webtank.net.http.uri, webtank.net.http.headers;

// version = cgi_script;

class ServerRequest  //Запрос к нашему приложению
{	RequestHeaders headers;

protected:
	RequestCookie _cookie; //Куки из запроса
	string[string] _POST;
	string[string] _GET;
	
	string[][string] _POSTArray;
	string[][string] _GETArray;
public:
	this(RequestHeaders headersParam, string messageBodyParam)
	{	headers = headersParam;
		messageBody = messageBodyParam;
		
		
		queryString = separateQuery( headers["request-uri"] );
		_cookie = new RequestCookie( headers["cookie"] );
		referer = headers["referer"];
		host = headers["host"];
		userAgent = headers["user-agent"];
	}
	
	//Получение кукев из запроса (сюда записывать нельзя)
	RequestCookie cookie() @property
	{	return _cookie; }
		
	//Данные переданные через стандартный ввод (методом POST)
	string[string] postVars() @property
	{	if( _POST.length <= 0 )
			_POST = extractURIData( messageBody );
		return _POST;
	}
	
	string[][string] postVarsArray() @property
	{	if( _POSTArray.length <= 0 )
			_POSTArray = extractURIDataArray( messageBody );
		return _POSTArray;
	}
	
	//Некоторые данные из HTTP-заголовков запроса к приложению
	immutable(string) referer;
	immutable(string) host;
	immutable(string) userAgent;
	immutable(string) messageBody;
	immutable(string) queryString;
	
	//Данные из URI строки запроса
	string[string] queryVars() @property
	{	if( _GET.length <= 0 )
			_GET = extractURIData( queryString );
		return _GET;
	}
	
	string[][string] queryVarsArray() @property
	{	if( _GETArray.length <= 0 )
			_GETArray = extractURIDataArray( queryString );
		return _GETArray;
	}

} 
