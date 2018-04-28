module mkk_site.security.common.user_identity;

import webtank.security.access_control;
public import mkk_site.security.common.session_id;

class MKKUserIdentity: AnonymousUser
{
	this(
		string login, string name,
		string[] accessRoles,
		string[string] data,
		ref const(SessionId) sid
	) {
		_login = login;
		_name = name;
		_accessRoles = accessRoles;
		_data = data;
		_sessionId = sid;

		// Добавим название группы и в словарь с доп. данными, чтобы можно было узнать его извне
		import std.array: join;
		_data["accessRoles"] = roles.join(`;`);
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
		bool isInRole(string roleName)
		{
			import std.algorithm: canFind;
			return _accessRoles.canFind(roleName);
		}

		///Делает текущий экземпляр удостоверения пользователя недействительным
		void invalidate() {
			_login = null;
			_name = null;
			_accessRoles = null;
			_data = null;
			_sessionId = SessionId.init;
		}
	}
	
	///Идентификатор сессии
	ref const(SessionId) sessionId() @property {
		return _sessionId;
	}

protected:
	SessionId _sessionId; 
	string _login;
	string[] _accessRoles;
	string _name;
	string[string] _data;
}