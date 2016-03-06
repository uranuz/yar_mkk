module mkk_site.utils;

import std.file, std.algorithm : endsWith;

import webtank.templating.plain_templater, webtank.db.database, webtank.net.http.context;

import mkk_site.site_data;
import mkk_site;

string buildNormalPath(T...)(T args)
{
	import std.path: buildNormalizedPath;
	import std.algorithm: endsWith;
	
	string result = buildNormalizedPath(args);
	
	static if( args.length > 0 )
	{
		//Возвращаем на место слэш в конце пути, который выкидывает стандартная библиотека
		if( result.length > 1 && args[$-1].endsWith("/") && !result.endsWith("/") )
			result ~= '/'; 
	}
	
	return result;
}

PlainTemplater getGeneralTemplate(HTTPContext context)
{	auto tpl = getPageTemplate(generalTemplateFileName);
	tpl.set("this page path", context.request.uri.path);

	if( context.request.uri.path.endsWith("/dyn/auth")  ) //Записываем исходный транспорт
		tpl.set( "transport_proto", context.request.headers.get("x-forwarded-proto", "http") );

	tpl.set( "authentication uri", getAuthRedirectURI(context) );
	
	string authMenuCaption;
	
	if( context.user.isAuthenticated )
	{	
		tpl.set( "without auth class", "is-hidden" );
		tpl.set( "user name", context.user.name );
		tpl.set( "user login", context.user.id );
	}
	else
	{	
		tpl.set( "with auth class", "is-hidden" );
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
	PlainTemplater tpl = templateCache.get(tplFileName);
	
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

import webtank.db.database, webtank.db.postgresql;

IDatabase _commonDatabase;
IDatabase _authDatabase;

static this()
{
	//Создаем объекты подключений при старте нити исполнения
	_commonDatabase = new DBPostgreSQL(commonDBConnStr);
	_authDatabase = new DBPostgreSQL(authDBConnStr);
}

IDatabase getCommonDB()
{	return _commonDatabase;
}

IDatabase getAuthDB()
{	return _authDatabase;
}

string[] parseExtraFileLink(string linkPair)
{	import std.algorithm : splitter;
	import std.algorithm : startsWith;
	auto linkPairSplitter = splitter(linkPair, "><");
	string link = linkPairSplitter.empty ? null : linkPairSplitter.front;
	string comment;

	if( link.length > 0 && link.length+2 < linkPair.length )
		comment = linkPair[ link.length+2..$ ];
	else
	{	if( !linkPair.startsWith("><") )
			link = linkPair;
	}

	return [ link, comment ];
}