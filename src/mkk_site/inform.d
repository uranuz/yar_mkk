module mkk_site.inform;

import std.conv, std.string, std.file, std.array;

import webtank.datctrl, webtank.db, webtank.net.http, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;
import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint,webtank.datctrl.record, webtank.net.http.context;


import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, mkk_site;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "inform";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.queryForm;
	auto qVars = rq.bodyForm;

	string о_ресурсе = 
`<h5>Добро пожаловать на сайт!</h5></br>
	
	<p><h4>Сведения о базе МКК</h4>
  Ресурс хранит сведения о планируемых, заявленных, пройденных и защищённых походах <br>
  и их участниках.</p>
<p> <h5>Задачей ресурса ставится: </h5></p>

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
       
       
<p><br><h5>За основу взята информация Ярославской маршрутно-квалификационной комиссии.</h5></p>
  <p>Содержит дополнительные сведения о правилах проведения туристских походов
  и сопутствущую информацию.</p>
  <p>&nbsp;&nbsp;</p>
<p> В отличии от многих интернет ресурсов не предполагает автоматическую саморегистрацию
  и полностью самостоятельный самоввод информации о пройденных и планируемых туристских походах.
  Ввод информации происходит через выделенных территориальных модераторов, являющихся (как правило) 
  членами или экспертами, туристских маршрутно-квалификационных комиссий.</p>
  <br>
<p>База строится, исходя из двух потоков данных.</p>
  
<h5>Туристы: </h5>
<p>
<ul style="margin-left: 20px;">
  <li> &nbsp;&nbsp; участники и руководители заявленных туристско-спортивных походов;</li> 
  <li> &nbsp;&nbsp; не заявленные туристы, жепающие зарегистрироваться в базе МКК.</li> 
    </ul>
</p>
       <br> 
  <p>     
       
  <h5>В открытом доступе отображаются:</h5> ФИО, дата рождения, опыт туриста и его квалификация.<br>
  По специальному соглашению могут отображаться контактные сведения<br>
  (электронный адрес или телефон, либо оба вместе).</p>
<p>
Последние сведения обязательны для модераторов, председателей видовых комиссий МКК,
  туристов обьявляющих о наборе групп,
  либо руководителей, заявленных походов в период до их завершения.
  </p>
  <p>&nbsp;&nbsp;</p>
 <p><h5> Походы, путешествия:</h5>
   <ul style="margin-left: 20px;">
  <li> &nbsp;&nbsp;походы и путешествия, прошедшие и проходящие заявку в системе МКК;</li>
  <li> &nbsp;&nbsp;походы и путешествия, не прошедшие официальную заявку,<br> &nbsp;&nbsp;&nbsp;&nbsp;но имеющие подтверждения о прохождении </li>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;через отчёты, кинофильмы и другие объективные источники;</li>
  <li> &nbsp;&nbsp;походы и путешествия прошедшие и проводимые в текуший период;</li>
  <li> &nbsp;&nbsp;планируемые походы и путешествия. </li>
    </ul>
   </p>
       <br> 
  
 <p><h5>Отображаемые сведения:</h5>
  
  <ul style="margin-left: 20px;">
  <li> &nbsp;&nbsp; номер маршрутной книжки (если имеется);</li>
  <li> &nbsp;&nbsp; сроки проведения похода;</li>
  <li> &nbsp;&nbsp; район похода, вид туризма;</li>
  <li> &nbsp;&nbsp; руководитель похода (инициатор проекта);</li>
  <li> &nbsp;&nbsp; нитка маршрута;</li>
  <li> &nbsp;&nbsp; состояние подготовки (идёт набор, проектируется, проходится, пройден, защищён и т.п.);</li>
  <li> &nbsp;&nbsp; комментарий руководителя;</li>
  <li> &nbsp;&nbsp; комментарий члена МКК (модератора).</li>
    </ul>
   </p>
       <br> 

	`;

	return о_ресурсе;
}
