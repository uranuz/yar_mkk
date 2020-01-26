module mkk.common.utils;

import webtank.net.http.context: HTTPContext;
import mkk.common.versions: isMKKSiteDevelTarget;

string getAuthRedirectURI(HTTPContext context)
{
	import webtank.net.http.headers.consts: HTTPHeader;
	
	string query = context.request.uri.query;
	//Задаем ссылку на аутентификацию
	static if( isMKKSiteDevelTarget )
		return
			"/dyn/auth?redirectTo=" ~ context.request.uri.path	~ "?" ~ query;
	else
		return
			"https://" ~ context.request.headers.get(HTTPHeader.XForwardedHost, "")
			~ "/dyn/auth?redirectTo="
			~ context.request.headers.get(HTTPHeader.XForwardedProto, "http") ~ "://"
			~ context.request.headers.get(HTTPHeader.XForwardedHost, "")
			~ context.request.uri.path ~ ( query.length ? "?" ~ query : "" );
}
