module mkk_site.utils;

import std.file;

import webtank.templating.plain_templater, webtank.db.database;

import mkk_site.site_data;

PlainTemplater getGeneralTemplate(string pagePath)
{	auto tpl = getPageTemplate(generalTemplateFileName);
	tpl.set("this page path", pagePath);
	return tpl;
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