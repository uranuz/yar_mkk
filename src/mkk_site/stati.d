module mkk_site.stati;

import std.conv, std.string, std.file, std.array;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "stati";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.bodyForm;
	auto qVars = rq.queryForm;

	string содержимоеГлавнойСтраницы = `
	<h2>Нормативные статьи и документы</h2>
	
	<p><a href="/pub/stati_dokument/Состав МКК_Ярославль_2015.xls">Состав Ярославской МКК 2016 - 2020 г. </a></p>
	<p><a href="/pub/stati_dokument/Marshrutka.doc">Маршрутная книжка</a></p>
	<p><a  href="/pub/stati_dokument/marshrutn_List.doc">Маршрутный лист</a></p>
	<p><a  href="/pub/stati_dokument/Spravka.doc">Справка о походе</a></p>
	<p><a  href="/pub/stati_dokument/tipovaya_forma_otcheta_o_pohode.doc">Форма отчёта о походе</a></p>
	<p><a href="/pub/stati_dokument/Спортивный туризм-правила.doc">Правила проведения походов</a></p>                                                       
	<p><a href="/pub/stati_dokument/TrekFinish120407-4.doc">Регламент</a></p>
	<p><a href="/pub/stati_dokument/TrekFinish120407-4.zip">Регламент (zip)</a></p>
	<p><a href="/pub/stati_dokument/stat1992_2010.rar"> Статистика. Отчёты за 1992 - 2010 годы (zip)</a></p>
	`;
	
	return содержимоеГлавнойСтраницы;
}
