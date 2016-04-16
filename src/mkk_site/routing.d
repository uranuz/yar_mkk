module mkk_site.routing;

import
	webtank.net.http.handler, 
	webtank.net.http.json_rpc_handler,
	webtank.net.http.context, 
	webtank.net.http.http;

import 
	mkk_site.site_data,
	mkk_site.uri_page_router;

import mkk_site.routing_init;

__gshared HTTPRouter Router;
__gshared MKK_Site_URIPageRouter PageRouter;
__gshared JSON_RPC_Router JSONRPCRouter;

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