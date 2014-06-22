module mkk_site.stati;

import std.conv, std.string, std.file, std.array;

import webtank.datctrl, webtank.db, webtank.net.http, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site;

immutable(string) thisPagePath;
immutable(string) authPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "stati";
	authPagePath = dynamicPath ~ "auth";
	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.bodyForm;
	auto qVars = rq.queryForm;

	string generalTplStr = cast(string) std.file.read( generalTemplateFileName );
	
	//Создаем шаблон по файлу
	auto tpl = getGeneralTemplate(context);

	if( context.user.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.user.id );
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
