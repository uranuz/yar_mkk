module webtank.net.http.request;

import std.json, std.socket;

import webtank.net.http.cookie, webtank.net.http.uri, webtank.net.http.headers;

// version = cgi_script;

class ServerRequest  //Запрос к нашему приложению
{	
protected:
	RequestCookie _cookie; //Куки из запроса
	string[string] _POST;
	string[string] _GET;
	
	string[][string] _POSTArray;
	string[][string] _GETArray;
	JSONValue _bodyJSON;
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

		_cookie = new RequestCookie( headers["cookie"] );
		uri = URI( headers["request-uri"] );
		rawURI = headers["request-uri"];
		referer = headers["referer"];
		userAgent = headers["user-agent"];
	}

	///Структура с информацией об идентификаторе запрашиваемого ресурса
	immutable(URI) uri;
	///HTTP заголовки запроса
	HTTPHeaders headers;

	///"Сырое" (недекодированое) значение идентификатора запрашиваемого ресурса
	immutable(string) rawURI;
	///"Тело сообщения" в том виде, каким оно пришло
	immutable(string) messageBody;
	///Referer - кто знает, тот поймет
	immutable(string) referer;
	///Описание клиентской программы и среды
	immutable(string) userAgent;

	///Данные HTTP формы переданные через адресную строку
	string[string] queryForm() @property
	{	if( _GET.length <= 0 )
			_GET = extractURIData( uri.query );
		return _GET;
	}

	///Множественные данные HTTP формы переданные через адресную строку
	///Используется, когда одному имени соответсвует несколько значений
	string[][string] queryFormMulti() @property
	{	if( _GETArray.length <= 0 )
			_GETArray = extractURIDataArray( uri.query );
		return _GETArray;
	}

	///Данные HTTP формы переданные в теле сообщения через POST, PUT
	string[string] bodyForm() @property
	{	if( _POST.length <= 0 )
			_POST = extractURIData( messageBody );
		return _POST;
	}

	///Множественные данные HTTP формы в теле сообщения через POST, PUT
	///Используется, когда одному имени соответсвует несколько значений
	string[][string] bodyFormMulti() @property
	{	if( _POSTArray.length <= 0 )
			_POSTArray = extractURIDataArray( messageBody );
		return _POSTArray;
	}

	//TODO: Реализовать HTTPRequest.form
	///Объединённый словарь данных HTTP формы переданных через адресную
	///строку и тело сообщения
//	string[string] form() @property {}

	//TODO: Реализовать HTTPRequest.formMulti
	///Объединённый словарь множественных данных HTTP формы переданных
	///через адресную строку и тело сообщения
	///Используется, когда одному имени соответсвует несколько значений
//	string[][string] formMulti() @property {}

	///Возвращает набор HTTP Cookie для текущего запроса
	RequestCookie cookie() @property
	{	return _cookie; }

	///Возвращает адрес удалённого узла, с которого пришёл запрос
	Address remoteAddress() @property
	{	return _remoteAddress;
	}
	
	///Возвращает адрес *этого* узла, который обрабатывает запрос
	Address localAddress() @property
	{	return _localAddress;
	}

	///Возвращает тело сообщения обработанное как объект JSON
	JSONValue bodyJSON() @property
	{	if( !_isJSONParsed)
		{	try { //Пытаемся распарсить messageBody в JSON
				_bodyJSON = parseJSON(messageBody);
			} catch (JSONException e) {
				_bodyJSON = JSONValue.init;
			} finally {
				_isJSONParsed = true;
			}
		}
		return _bodyJSON;
	}

} 
