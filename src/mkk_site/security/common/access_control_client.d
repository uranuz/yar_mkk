module mkk_site.security.common.access_control_client;

import webtank.security.access_control;
import webtank.net.http.context: HTTPContext;
import webtank.net.utils;
import webtank.net.service.endpoint;

import mkk_site.security.common.user_identity;
import mkk_site.common.service;
import webtank.net.std_json_rpc_client;

///Класс управляет выдачей билетов для доступа
class MKKAccessControlClient: IAccessController
{
	this() {}
public:
	///Реализация метода аутентификации контролёра доступа
	override IUserIdentity authenticate(Object context)
	{	auto httpCtx = cast(HTTPContext) context;
		
		if( httpCtx is null )
			return new AnonymousUser;
		else
			return authenticateSession(httpCtx);
	}

	///Метод выполняет аутентификацию сессии для HTTP контекста
	///Возвращает удостоверение пользователя
	IUserIdentity authenticateSession(HTTPContext context)
	{
		import std.json;
		import std.base64: Base64URL;
		auto jUserInfo = endpoint(`yarMKKMain`).remoteCall!JSONValue(`auth.baseUserInfo`, context);

		assert(jUserInfo.type == JSON_TYPE.OBJECT, `Base user info expected to be object!`);

		if( `userNum` !in jUserInfo || jUserInfo[`userNum`].type != JSON_TYPE.INTEGER ) {
			return new AnonymousUser();
		}

		SessionId sid;
		Base64URL.decode(context.request.cookies.get(`__sid__`, null), sid[]);

		//Получаем информацию о пользователе из результата запроса
		return new MKKUserIdentity(
			( `login` in jUserInfo && jUserInfo[`login`].type == JSON_TYPE.STRING? jUserInfo[`login`].str: null ),
			( `name` in jUserInfo && jUserInfo[`name`].type == JSON_TYPE.STRING? jUserInfo[`name`].str: null ),
			( `group` in jUserInfo && jUserInfo[`group`].type == JSON_TYPE.STRING? jUserInfo[`group`].str: null ),
			null,
			sid
		);
	}
}