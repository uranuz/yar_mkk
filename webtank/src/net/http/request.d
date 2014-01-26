module webtank.net.http.request;

import std.json, std.socket;

import webtank.net.http.cookie, webtank.net.http.uri, webtank.net.http.headers;

// version = cgi_script;

class ServerRequest  //Запрос к нашему приложению
{	HTTPHeaders headers;

protected:
	RequestCookie _cookie; //Куки из запроса
	string[string] _POST;
	string[string] _GET;
	
	string[][string] _POSTArray;
	string[][string] _GETArray;
	JSONValue _JSON_Body;
	bool _isJSONParsed = false;
	
	Address _remoteAddress;
	Address _localAddress;
public:
	this(
		HTTPHeaders headersParam, 
		string messageBodyParam,
		Address remoteAddressParam,
		Address localAddressParam
	)
	{	headers = headersParam;
		messageBody = messageBodyParam;
		_remoteAddress = remoteAddressParam;
		_localAddress = localAddressParam;
		
		queryString = separateQuery( headers["request-uri"] );
		path = separatePath( headers["request-uri"] );
		_cookie = new RequestCookie( headers["cookie"] );
		referer = headers["referer"];
		host = headers["host"];
		userAgent = headers["user-agent"];
	}
	
	///Возвращает набор HTTP Cookie для текущего запроса
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
	immutable(string) path;
	
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
	
	///Возвращает адрес удалённого узла, с которого пришёл запрос
	Address remoteAddress() @property
	{	return _remoteAddress;
	}
	
	///Возвращает адрес *этого* узла, который обрабатывает запрос
	Address localAddress() @property
	{	return _localAddress;
	}
	
	JSONValue JSON_Body() @property
	{	if( !_isJSONParsed)
		{	try { //Пытаемся распарсить messageBody в JSON
				_JSON_Body = parseJSON(messageBody);
			} catch (JSONException e) {
				_JSON_Body = JSONValue.init;
			} finally {
				_isJSONParsed = true;
			}
		}
		return _JSON_Body;
	}

} 
