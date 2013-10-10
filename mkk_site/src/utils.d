module mkk_site.utils;

import std.file;

import webtank.templating.plain_templater;

import mkk_site.site_data;

auto getGeneralTemplate(string pagePath)
{	//Строка с содержимым файла шаблона страницы 
	auto templateStr = 
		cast(string) std.file.read( generalTemplateFileName ); 

	auto tpl = new PlainTemplater( templateStr ); //Создаем шаблон по файлу
	//Задаём местоположения всяких файлов
	tpl.set("img folder", imgPath);
	tpl.set("css folder", cssPath);
	tpl.set("dynamic path", dynamicPath);
	tpl.set("useful links", "Куча хороших ссылок");
	tpl.set("js folder", jsPath);
	tpl.set("this page path", pagePath);
	
	tpl.set("webtank js folder", webtankJsPath);
	return tpl;
}