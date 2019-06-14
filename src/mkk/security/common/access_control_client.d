module mkk.security.common.access_control_client;

import webtank.security.access_control;
import webtank.net.http.context: HTTPContext;
import webtank.net.utils;

import mkk.security.common.user_identity;
import mkk.common.service;
import webtank.net.std_json_rpc_client;

///Класс управляет выдачей билетов для доступа
class MKKAccessControlClient: IAccessController
{
	this() {}
public:
	///Реализация метода аутентификации контролёра доступа
	override IUserIdentity authenticate(Object context)
	{
		//debug import std.stdio: writeln;
		auto httpCtx = cast(HTTPContext) context;

		//debug writeln(`TRACE authenticate 1`);
		if( httpCtx !is null ) {
			//debug writeln(`TRACE authenticate 2`);
			return authenticateSession(httpCtx);
		}
		//debug writeln(`TRACE authenticate 3`);
		return new AnonymousUser;
	}

	///Метод выполняет аутентификацию сессии для HTTP контекста
	///Возвращает удостоверение пользователя
	IUserIdentity authenticateSession(HTTPContext ctx)
	{
		//debug import std.stdio: writeln;
		//debug writeln(`TRACE authenticateSession 1`);
		import std.json: JSON_TYPE, JSONValue;
		// Запрос получает минимальную информацию о пользователе по Ид. сессии в контексте
		auto jUserInfo = ctx.endpoint(`yarMKKMain`).remoteCall!JSONValue(`auth.baseUserInfo`);

		//debug writeln(`TRACE authenticateSession jUserInfo: `, jUserInfo);

		import std.exception: enforce;
		enforce(jUserInfo.type == JSON_TYPE.OBJECT, `Base user info expected to be object!`);

		if( `userNum` !in jUserInfo || jUserInfo[`userNum`].type != JSON_TYPE.INTEGER ) {
			return new AnonymousUser();
		}
		//debug writeln(`TRACE authenticateSession 2`);

		import std.base64: Base64URL;
		SessionId sid;
		Base64URL.decode(ctx.request.cookies.get(`__sid__`), sid[]);

		import std.algorithm: splitter, filter;
		import std.array: array;

		//Получаем информацию о пользователе из результата запроса: логин, имя, роли доступа
		string login; string name; string[] accessRoles;
		if( auto it = `login` in jUserInfo ) {
			login = it.type == JSON_TYPE.STRING? it.str: null;
		}
		if( auto it = `name` in jUserInfo ) {
			name = it.type == JSON_TYPE.STRING? it.str: null;
		}
		if( auto it = `accessRoles` in jUserInfo ) {
			accessRoles = it.type == JSON_TYPE.STRING? it.str.splitter(`;`).filter!( (it) => it.length > 0 ).array: null;
		}
		//debug writeln(`TRACE authenticateSession 3`);
		return new MKKUserIdentity(login, name, accessRoles, /*data=*/null, sid);
	}
}