module webtank.net.http.context;

import webtank.net.http.request, webtank.net.http.response, webtank.security.access_control;

class HTTPContext
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
	
	///Удостоверение пользователя
	IUserIdentity user() @property
	{	return _userIdentity; }
	
	void _setuser(IUserIdentity newIdentity) 
	{	if( _userIdentity is null )
			_userIdentity = newIdentity;
		else
			throw new Exception("Access ticket for connection is already set!!!");
	}
	
protected:
	ServerRequest _request;
	ServerResponse _response;
	IUserIdentity _userIdentity;
}