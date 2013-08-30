module mkk_site.admin;

import std.process, std.conv, std.datetime;

import webtank.net.application/+, webtank.net.web_server+/;

import mkk_site.site_data, mkk_site.authentication;

static this()
{	Application.setHandler(&netMain, dynamicPath ~ "adminka");
	Application.setHandler(&netMain, dynamicPath ~ "adminka/");
}

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );
	
	if( !auth.isIdentified() || ( auth.userInfo.group != "admin" ) )
	{	rp.headers["status-code"] = "403";
		rp.headers["reason-phrase"] = "Forbidden";
		rp.write( generateServicePageContent(403) );
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

