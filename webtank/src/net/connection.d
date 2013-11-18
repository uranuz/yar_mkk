module webtank.net.connection;

import webtank.net.access_control;

///Интерфейс базового контекста подключения
interface IConnectionContext
{	
	///Билет доступа
	IAccessTicket accessTicket() @property;
}