module mkk_site.utils;

import std.file, std.algorithm : endsWith;

import webtank.templating.plain_templater, webtank.db.database, webtank.net.http.context;

import mkk_site.site_data;

PlainTemplater getGeneralTemplate(HTTPContext context)
{	auto tpl = getPageTemplate(generalTemplateFileName);
	tpl.set("this page path", context.request.uri.path);

	if( context.request.uri.path.endsWith("/dyn/auth")  ) //Записываем исходный транспорт
		tpl.set( "transport_proto", context.request.headers.get("x-forwarded-proto", "http") );

	tpl.set( "authentication uri", getAuthRedirectURI(context) );
	
	if( context.user.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.user.id );
	}
	else
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}
	return tpl;
}



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

PlainTemplater getPageTemplate(string tplFileName, bool shouldInit = true)
{	
	import std.file;
	string templateStr;
	
	if( std.file.exists(tplFileName) )
		templateStr = cast(string) std.file.read( tplFileName ); 

	auto tpl = new PlainTemplater( templateStr ); //Создаем шаблон по файлу
	
	if( shouldInit )
	{	//Задаём местоположения всяких файлов

		tpl.set("public folder", publicPath);
		tpl.set("img folder", imgPath);
		tpl.set("css folder", cssPath);
		tpl.set("js folder", jsPath);
		
		tpl.set("webtank public folder", webtankPublicPath);
		tpl.set("webtank img folder", webtankImgPath);
		tpl.set("webtank css folder", webtankCssPath);
		tpl.set("webtank js folder", webtankJsPath);
		
		tpl.set("dynamic path", dynamicPath);
	}
	
	return tpl;
}

IDatabase getCommonDB()
{	import webtank.db.postgresql;
	return new DBPostgreSQL(commonDBConnStr);
}

string[] parseExtraFileLink(string linkPair)
{	import webtank.common.utils;
	import std.algorithm : startsWith;
	string link = linkPair.splitFirst("><");
	string comment;

	if( link.length > 0 && link.length+2 < linkPair.length )
		comment = linkPair[ link.length+2..$ ];
	else
	{	if( !linkPair.startsWith("><") )
			link = linkPair;
	}

	return [ link, comment ];
}