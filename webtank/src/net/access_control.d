module webtank.net.access_control;

import webtank.net.connection;

///Интерфейс билета для доступа к системе
interface IAccessTicket
{
	///Пользователь-владелец билета
	IUser user() @property;
	
	///Возвращает true, если владелец успешно прошёл проверку подлинности. Иначе false
	///Замечание: Для определения подлинности пользователя недостаточно проверки
	///инициализации билета. Необходимо проверять это свойство
	// 	if( ticket is null ) {
	// 		//Не удаётся проверить пользователя
	// 	} else {
	// 		if( ticket.isAuthenticated ) {
	// 			//Пользователь прошёл аутентификацию
	// 		} else {
	// 			//Пользователь не аутентифицирован
	// 		}
	// 		
	// 	}
	bool isAuthenticated() @property;
}


///Интерфейс пользователя
interface IUser
{
	///Идентификационная строка
	string login() @property;
	
	///Функция возвращает true, если пользователь входит в группу
	bool isInGroup(string groupName);
	
	///Публикуемое имя пользователя
	string name() @property;
	
	///Адрес эл. почты пользователя для рассылки служебной информации от сервера
	string email() @property;
}


///Интерфейс упра доступа к системе. Отвечает за получение информации
///о доступе к системе и выдачу билетов.
//TODO: Возможно создать класс AccountManager на основе этого класса
interface IAccessTicketManager
{	
	///Получение билета для доступа к системе
	IAccessTicket getTicket(IConnectionContext context);
}

///Интерфейс разрешения доступа
// interface IAccessPermission
// {
// 	
// 	
// }