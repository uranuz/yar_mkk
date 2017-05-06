module mkk_site.user_identity;

import webtank.security.access_control;

enum uint sessionIdByteLength = 48; //Количество байт в ИД - сессии
enum uint sessionIdStrLength = sessionIdByteLength * 8 / 6;  //Длина в символах в виде base64 - строки
alias ubyte[sessionIdByteLength] SessionId; //Тип: ИД сессии

class MKKUserIdentity: AnonymousUser
{
	this(
		string login, string name,
		string group, string[string] data,
		ref const(SessionId) sid
	) {
		_login = login;
		_name = name;
		_group = group;
		_data = data;
		_sessionId = sid;
	}
	
	override {
		///Строка для идентификации пользователя
		string id() @property {
			return _login;
		}
		
		///Публикуемое имя пользователя
		string name() @property {
			return _name;
		}
		
		///Дополнительные данные пользователя
		string[string] data() {
			return _data;
		}
		
		///Возвращает true, если владелец успешно прошёл проверку подлинности. Иначе false
		bool isAuthenticated() @property {
			return ( ( _sessionId != SessionId.init ) /+&& ( _userInfo != anonymousUI )+/  ); //TODO: Улучшить проверку
		}
		
		///Функция возвращает true, если пользователь входит в группу
		bool isInRole( string roleName ) {
			return ( roleName == _group );
		}

		///Делает текущий экземпляр удостоверения пользователя недействительным
		void invalidate() {
			_login = null;
			_name = null;
			_group = null;
			_data = null;
			_sessionId = SessionId.init;
		}
	}
	
	///Идентификатор сессии
	ref const(SessionId) sessionId() @property
	{	return _sessionId; }

protected:
	SessionId _sessionId; 
	string _login;
	string _group;
	string _name;
	string[string] _data;
}