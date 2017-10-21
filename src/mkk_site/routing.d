module mkk_site.routing;

import
	webtank.net.http.handler,
	webtank.net.http.json_rpc_handler,
	webtank.net.http.context,
	webtank.net.http.http;

import
	mkk_site.site_data_old,
	mkk_site.uri_page_router;

string getAuthRedirectURI(HTTPContext context)
{	string query = context.request.uri.query;
	//Задаем ссылку на аутентификацию
	static if( isMKKSiteDevelTarget )
		return
			dynamicPath ~ "auth?redirectTo=" ~ context.request.uri.path
			~ "?" ~ context.request.uri.query;
	else
		return
			"https://" ~ context.request.headers.get("x-forwarded-host", "")
			~ dynamicPath ~ "auth?redirectTo="
			~ context.request.headers.get("x-forwarded-proto", "http") ~ "://"
			~ context.request.headers.get("x-forwarded-host", "")
			~ context.request.uri.path ~ ( query.length ? "?" ~ query : "" );
}