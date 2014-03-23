module mkk_site.utils;

import std.file, std.algorithm : endsWith;

import webtank.templating.plain_templater, webtank.db.database, webtank.net.http.context;

import mkk_site.site_data;

PlainTemplater getGeneralTemplate(HTTPContext context)
{	auto tpl = getPageTemplate(generalTemplateFileName);
	tpl.set("this page path", context.request.uri.path);

	if( context.request.uri.path.endsWith("/dyn/auth")  ) //Записываем исходный транспорт
		tpl.set( "transport_proto", context.request.headers.get("x-forwarded-proto", "http") );

	if( context.user.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.user.id );
	}
	else
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}
	return tpl;
}



// string getAuthRedirectURI(HTTPContext context)
// {	//Задаем ссылку на аутентификацию
// 	static if( buildTarget == BuildTarget.devel )
// 		tpl.set("authentication uri", dynamicPath ~ "auth?redirectTo=" ~ context.request.uri.path );
// 	else
// 		tpl.set("authentication uri",
// 			"https://" ~ dynamicPath ~ "auth?redirectTo="
// 			~ context.request.headers.get("x-forwarded-proto", "http")
// 			~ context.request.headers.get("x-forwarded-host", "")
// 			~ context.request.uri.path
// 		);
// 	
// }

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