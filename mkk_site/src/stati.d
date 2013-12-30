module mkk_site.stati;

import std.conv, std.string, std.file, std.stdio, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils, mkk_site._import;

immutable thisPagePath = dynamicPath ~ "stati";
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
	auto tpl = getGeneralTemplate(thisPagePath);

	if( context.accessTicket.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.accessTicket.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.accessTicket.user.login );
	}
	else 
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}

	string содержимоеГлавнойСтраницы = `
	<h2>Нормативные статьи и документы</h2>
	
	<p><a href="/pub/stati_dokument/Marshrutka.doc"           >Маршрутная книжка.     </a></p>
	<p><a  href="/pub/stati_dokument/marshrutn_List.doc"      >Маршрутный лист.       </a></p>
	<p><a  href="/pub/stati_dokument/Spravka.doc"          >Справка о походе.      </a></p>
	<p><a  href="/pub/stati_dokument/tipovaya_forma_otcheta_o_pohode.doc">
	                                                         Форма отчёта о походе. </a></p>
	<p><a href="/pub/stati_dokument/Спортивный туризм-правила.doc">Правила проведения походов.   </a></p>                                                       
	<p><a href="/pub/stati_dokument/TrekFinish120407-4.doc"    >Регламент.      </a></p>
	<p><a href="/pub/stati_dokument/TrekFinish120407-4.zip"   >Регламент.(zip) </a></p>
	
	`;
	tpl.set( "content", содержимоеГлавнойСтраницы );
	
	
	rp ~= tpl.getString();
}
