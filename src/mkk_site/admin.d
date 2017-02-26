module mkk_site.admin;

import std.conv, std.datetime;

import webtank.net.http.router, webtank.net.http.request, webtank.net.http.response;

import mkk_site.site_data_old, mkk_site.access_control;

static this()
{	Router.setPathHandler(dynamicPath ~ "adminka", &netMain);
}

string netMain(ServerRequest rq, ServerResponse rp)  //Определение главной функции приложения
{	
	auto auth = new Authentication( rq.cookies.get("sid", null), authDBConnStr, eventLogFileName );
	
	if( !auth.isIdentified() || ( auth.userInfo.group != "admin" ) )
	{	rp.headers["status-code"] = "403";
		rp.headers["reason-phrase"] = "Forbidden";
// 		rp.write( generateServicePageContent(403) );
		rp.write( "<h3>403 Forbidden</h3>" );
		return;
	}
	else 
	{	
		rp ~= "<html><body>";
		rp ~= "<h2>Добро пожаловать, товарищ " ~ auth.userInfo.name ~ "!!!</h2>";
		rp ~= "Сервер работает с " ;
		rp ~= `<hr><p style="text-align: right;">webtank.net.web_server</p></body></html>`;
	}
}

