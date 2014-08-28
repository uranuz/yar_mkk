module mkk_site.reports;

import std.conv, std.string, std.file, std.array;

import webtank.datctrl, webtank.db, webtank.net.http, webtank.templating.plain_templater, webtank.net.utils;

import mkk_site;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "reports";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.bodyForm;
	auto qVars = rq.queryForm;

	string содержимоеГлавнойСтраницы = `
	<h2>Отчёты о походах</h2>
	
	<p>Отчёты 2013 года.  </p>
	<p><a href="http://yadi.sk/d/9P4YLRL3JqsY8"         >Жомболок - Ока.     </a></p>
	<p><a href="http://yadi.sk/d/J6qlFdMoJqsZZ"         >Чирка - Кемь.   </a></p>
	<p><a href="http://yadi.sk/d/a42c7qJY943eD"         >Косью.   </a></p>
	
	<p>Отчёты 2012 года.  </p>
	<p><a href="/pub/reports/2012/Отчет кавказ 2012.doc"           > Кавказ.     </a></p>
	<p><a href="/pub/reports/2012/Отчет Камчатка 2012.doc"         > Камчатка.   </a></p>
	<p><a href="/pub/reports/2012/Отчет Она Абакан 2012.doc"       > Она Абакан. </a></p>
	<p><a href="/pub/reports/2012/Отчет Ю.Буг 2012.doc"            > Ю.Буг.      </a></p>
	<p><a href="/pub/reports/2012/Отчёт Лахость 2012.doc"           > Лахость.     </a></p>
	<p><a href="/pub/reports/2012/Отчета  Писта 2012.doc"           >  Писта.     </a></p>
	<p><a href="/pub/reports/2012/Сводный.xlsx"           >Сводный чемпионата походов Ярославской области 2012 года.xlsx.     </a></p>
	<p><a href="/pub/reports/2012/Marshrutka.doc"           >Маршрутная книжка.     </a></p>
	
	`;
	
	return содержимоеГлавнойСтраницы;
}
