module mkk_site.index;

import std.conv, std.string, std.file, std.stdio, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "index";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
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
	Добро пожаловать на сайт!
	<p><h1>База МКК</h1><br>
  Ресурс хранит сведения о планируемых, заявленных, пройденных и защищённых походах <br>
  и их участниках.</p>
<p> <h2>Задачей ресурса ставится: </h2></p>

<p>
<div>
<ul style="margin-left: 20px;">
<li>  &nbsp;&nbsp;создание достоверной информационной базы <br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;по пройденным и планируемым туристским походам;<br> </li> 
 <li> &nbsp;&nbsp;облегчения поиска информации о планируемых походах;</li> 
 <li> &nbsp;&nbsp;создание интернет площадки для формирования туристских групп;</li> 
 <li> &nbsp;&nbsp;создания системы дистанционной заявки на туристские маршруты.</li> 
</ul>
  </div>
        </p>
       
       <p>&nbsp;&nbsp;</p>
<p><h2>За основу взята информация Ярославской маршрутно-квалификационной комиссии.</h2></p>
  <p>Содержит дополнительные сведения о правилах проведения туристских походов<br>
  и сопутствущую информацию.</p>
  <p>&nbsp;&nbsp;</p>
<p> В отличии от многих интернет ресурсов не предполагает автоматическую саморегистрацию <br>
  и полностью самостоятельный самоввод информации о пройденных и планируемых туристских походах.<br>
  Ввод информации происходит через выделенных территориальных модераторов, являющихся (как правило)<br>
  членами или экспертами, туристских маршрутно-квалификационных комиссий.<br>
  База строится исходя из двух потоков данных.</p>
  <p>&nbsp;&nbsp;</p>
  
<p> <h2>Туристы: </h2>
<ul style="margin-left: 20px;">
  <li> &nbsp;&nbsp; участники и руководители заявленных туристско-спортивных походов;</li> 
  <li> &nbsp;&nbsp; не заявленные туристы, жепающие зарегистрироваться в базе МКК.</li> 
    </ul>
   </p>
       <br> 
  В открытом доступе отображаются: ФИО, дата рождения, опыт туриста и его квалификация.<br>
  По специальному соглашению могут отображаться контактные сведения<br>
  (электронный адрес или телефон, либо оба вместе).</p>
<p>
Последние сведения обязательны для модераторов, председателей видовых комиссий МКК,<br>
  туристов обьявляющих о наборе групп,<br>
  либо руководителей, заявленных походов в период до их завершения.<br> 
  </p>
  <p>&nbsp;&nbsp;</p>
 <p><h2> Походы, путешествия:</h2>
   <ul style="margin-left: 20px;">
  <li> &nbsp;&nbsp;походы и путешествия, прошедшие и проходящие заявку в системе МКК;</li>
  <li> &nbsp;&nbsp;походы и путешествия, не прошедшие официальную заявку,<br> &nbsp;&nbsp;&nbsp;&nbsp;но имеющие подтверждения о прохождении </li>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;через отчёты, кинофильмы и другие объективные источники;</li>
  <li> &nbsp;&nbsp;походы и путешествия прошедшие и проводимые в текуший период;</li>
  <li> &nbsp;&nbsp;планируемые походы и путешествия. </li>
    </ul>
   </p>
       <br> 
  
 <p><h2>Отображаемые сведения:</h2>
  
  <ul style="margin-left: 20px;">
  <li> &nbsp;&nbsp; номер маршрурной книжки (если имеется);</li>
  <li> &nbsp;&nbsp;сроки проведения похода;</li>
  <li> &nbsp;&nbsp;район похода, вид туризма;</li>
  <li> &nbsp;&nbsp;руководитель похода (инициатор проекта);</li>
  <li> &nbsp;&nbsp; нитка маршрута;</li>
  <li> &nbsp;&nbsp; состояние подготовки (идёт набор, проектируется, проходится, пройден, защищён и т.п.);</li>
  <li> &nbsp;&nbsp; комментарий руководителя;</li>
  <li> &nbsp;&nbsp; комментарий члена МКК (модератора).</li>
    </ul>
   </p>
       <br> 
  
  
	`;
	tpl.set( "content", содержимоеГлавнойСтраницы );
	
	
	rp ~= tpl.getString();
}
