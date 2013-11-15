module webtank.net.access_control;

///Интерфейс билета с информацией для доступа к системе
interface IAccessTicket
{
	///Владелец билета
	IServerUser user() @property;
	
	///Возвращает true, если владелец успешно прошёл проверку подлинности. Иначе false
	bool isAuthenticated() @property;
}


///Интерфейс пользователя сервера
interface IServerUser
{
	///Строка для идентификации пользователя
	string login() @property;
	
	///Функция возвращает true, если пользователь входит в группу
	bool isInGroup(string groupName);
	
	///Публикуемое имя пользователя
	string name() @property;
	
	///Адрес эл. почты пользователя для рассылки служебной информации от сервера
	string email() @property;
}

///Интерфейс правила аутентификации
interface IAuthenticationRule
{	IAccessTicket authenticate(Object context);
}