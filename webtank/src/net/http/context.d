module webtank.net.http.context;

import webtank.net.http.request, webtank.net.http.response;

class HTTPContext
{	
// 	this(ServerRequest rq, ServerResponse rp)
// 	{	request = rq;
// 		response = rp;
// 	}
	///Объект запроса к серверу по протоколу HTTP
	ServerRequest request;
	
	///Ответ объекта сервера
	ServerResponse response;
	
	///Билет контроля доступа
	IAccessTicket accessTicket; 
	
}