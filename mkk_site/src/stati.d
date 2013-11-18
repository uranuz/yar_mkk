module mkk_site.stati;

import std.conv, std.string, std.file, std.stdio, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "stati";
immutable authPagePath = dynamicPath ~ "auth";

static this()
{	Router.setPathHandler(thisPagePath, &netMain);
}


void netMain(ServerRequest rq, ServerResponse rp)  //Определение главной функции приложения
{	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );

	string generalTplStr = cast(string) std.file.read( generalTemplateFileName );
	
	//Создаем шаблон по файлу
	auto tpl = getGeneralTemplate(thisPagePath);

	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ auth.userInfo.name ~ "</b>!!!</i>");
	tpl.set("user login", auth.userInfo.login );

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
