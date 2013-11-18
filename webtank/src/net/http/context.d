module webtank.net.http.context;

import webtank.net.connection, webtank.net.http.request, webtank.net.http.response, webtank.net.access_control;

class HTTPContext: IConnectionContext
{	
	this(ServerRequest rq, ServerResponse rp)
	{	_request = rq;
		_response = rp;
	}
	///Запрос к серверу по протоколу HTTP
	ServerRequest request() @property
	{	return _request; }
	
	///Объект ответа сервера
	ServerResponse response() @property
	{	return _response; }
	
	///Билет доступа
	override IAccessTicket accessTicket() @property
	{	return _accessTicket; }
	
	void _setAccessTicket(IAccessTicket ticket) 
	{	if( _accessTicket is null )
			_accessTicket = ticket;
		else
			throw new Exception("Access ticket for connection is already set!!!");
	}
	
protected:
	ServerRequest _request;
	ServerResponse _response;
	IAccessTicket _accessTicket;
}