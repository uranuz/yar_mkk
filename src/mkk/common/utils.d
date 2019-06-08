module mkk.common.utils;

import webtank.net.http.context: HTTPContext;
import mkk.common.versions: isMKKSiteDevelTarget;

string getAuthRedirectURI(HTTPContext context)
{
	string query = context.request.uri.query;
	//Задаем ссылку на аутентификацию
	static if( isMKKSiteDevelTarget )
		return
			"/dyn/auth?redirectTo=" ~ context.request.uri.path	~ "?" ~ query;
	else
		return
			"https://" ~ context.request.headers.get("x-forwarded-host", "")
			~ "/dyn/auth?redirectTo="
			~ context.request.headers.get("x-forwarded-proto", "http") ~ "://"
			~ context.request.headers.get("x-forwarded-host", "")
			~ context.request.uri.path ~ ( query.length ? "?" ~ query : "" );
}
