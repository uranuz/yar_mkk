module mkk_site.reports;

import std.conv, std.string, std.file, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, mkk_site._import;

immutable thisPagePath = dynamicPath ~ "reports";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	
	string generalTplStr = cast(string) std.file.read( generalTemplateFileName );
	
	//Создаем шаблон по файлу
	auto tpl = getGeneralTemplate(context);

	string содержимоеГлавнойСтраницы = `
	<h2>Отчёты о походах</h2>
	
	<p>Отчёты 2012 года.  </p>
	<p><a href="/pub/reports/2012/Отчет кавказ 2012.doc"           >Отчет Кавказ.     </a></p>
	<p><a href="/pub/reports/2012/Отчет Камчатка 2012.doc"         >Отчет Камчатка.   </a></p>
	<p><a href="/pub/reports/2012/Отчет Она Абакан 2012.doc"       >Отчет Она Абакан. </a></p>
	<p><a href="/pub/reports/2012/Отчет Ю.Буг 2012.doc"            >Отчет Ю.Буг.      </a></p>
	<p><a href="/pub/reports/2012/Отчёт Лахость 2012.doc"           >Отчёт Лахость.     </a></p>
	<p><a href="/pub/reports/2012/Отчета  Писта 2012.doc"           >Отчета  Писта.     </a></p>
	<p><a href="/pub/reports/2012/Сводный 2012.xlsx"           >Сводный чемпионата походов <br> Ярославской области 2012 года.xlsx.     </a></p>
	<p><a href="/pub/reports/2012/Marshrutka.doc"           >Маршрутная книжка.     </a></p>
	
	
	`;
	tpl.set( "content", содержимоеГлавнойСтраницы );
	
	
	rp ~= tpl.getString();
}
