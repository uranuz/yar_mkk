module mkk_site.index;

import std.conv, std.string, std.file, std.array, std.typecons;

import webtank.datctrl, webtank.db, webtank.net.http, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;
import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint,webtank.datctrl.record, webtank.net.http.context;


import mkk_site;

immutable(string) thisPagePath;
immutable(string) authPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "index";
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
	
		//---------------------------
	string output; //"Выхлоп" программы 
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
	//------------------------------------
	
	
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		//-----------------------------------------

	auto pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Номер книги", 
		string, "Сроки", 
		typeof(видТуризма), "Вид", 
		typeof(категорияСложности), "кс", 
		typeof(элементыКС), "элем",
		string,"Район",
		string,"Руководитель", 
		
		string,"Город,<br>организация",	
		string, "Нитка маршрута",
		string, "Коментарий руководителя",
		typeof(готовностьПохода), "Готовность",
		typeof(статусЗаявки), "Статус"
	)(
		null,
		tuple(
			видТуризма,
			категорияСложности,
			элементыКС,
			готовностьПохода,
			статусЗаявки
		)
	);
	//WHERE
	
	string queryStr = // основное тело запроса
	`with 
t_chef as (
 select pohod.num,/*номер похода*/
         
        (
    coalesce(T.family_name,'нет данных')||'&nbsp;'
  ||coalesce(T.given_name,'')||'&nbsp;'
  ||coalesce(T.patronymic,'')||'&nbsp;'
  ||coalesce(T.birth_year::text,'')
        ) as fio  
 /* создаётся таблица номера руководителей похода - их ФИО г.р.*/

from pohod
 LEFT join tourist T
   on pohod.chef_grupp = T.num
)


	  select pohod.num,
   (coalesce(kod_mkk,'000-00')||'&nbsp;&nbsp;&nbsp;'||coalesce(nomer_knigi,'00-00')) as nomer_knigi,   
     (
    date_part('day', begin_date)||'.'||
    date_part('month', begin_date)||'.'||
    date_part('YEAR', begin_date) 
    
      ||' &nbsp;&nbsp;по &nbsp;&nbsp'||
    date_part('day', finish_date)||'.'||
    date_part('month', finish_date)||'.'||
    date_part('YEAR', finish_date)
     ) as dat ,  
      vid,
      ks,
      elem,

     region_pohod , 
     t_chef.fio , 
     
     /*(coalesce(gr,'')) as gr, */
     
     (coalesce(organization,'')||'<br>'||coalesce(region_group,'')) as organiz, 
     (coalesce(marchrut::text,'')) as marchrut, 
     (coalesce(chef_coment::text,'')) as chef_coment, 
     coalesce(prepar,'0') as prepar,
        coalesce(stat,'0') as stat 
             from pohod 
               
       

       LEFT OUTER JOIN t_chef
      on t_chef.num = pohod.num  `; 
      
      queryStr~=`WHERE  (pohod.reg_timestamp is not null )   order by  pohod.reg_timestamp DESC  LIMIT 10  `;
      
      auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	
	
	
	// Начало сведний о последних десяти записях
	string last_dekada=` <h4>Недавно добавленные походы</h4>`~ "\r\n";
	
	foreach(rec; rs)
	{
		last_dekada~=`<hr style="color:green;"><p> <a  &nbsp;&nbsp;&nbsp  href="` ~ dynamicPath ~ `pohod?key=`
		~ rec.getStr!("Ключ")() ~ `">` ~ rec.getStr!("Вид")() ~
		`&nbsp;&nbsp;поход &nbsp;&nbsp;&nbsp`~ rec.getStr!("кс")() ~ `&nbsp;` ~ rec.getStr!("элем")("")
		~`&nbsp;к.с.&nbsp;&nbsp;в районе &nbsp;&nbsp;`
		~ rec.getStr!("Район")() ~ ` </a> </p>`~ "\r\n";
			
	
		last_dekada~=`<p class="last_pohod_comment"> По маршруту: `~ rec.getStr!("Нитка маршрута")() ~`  </br>` ~"\r\n";
		last_dekada~=`&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Руководитель группы &nbsp;&nbsp;`~ rec.getStr!("Руководитель")() ~`</br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Сроки похода c `~rec.getStr!("Сроки")() ~ "\r\n";
		last_dekada~=`</p></br>`~ "\r\n";
	}
	// Конец сведний о последних десяти записях

 string о_ресурсе_один = `
	 <h5>Добро пожаловать на сайт!</h5></br>

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
</ul><br>

<p style="text-align:right;"> <a href="` ~ dynamicPath ~ `inform" > 
Подробнее</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</p>
  </div>
        </p>
       
       <p>&nbsp;&nbsp;</p>`;
       
  
	
	string содержимоеГлавнойСтраницы;
	
	содержимоеГлавнойСтраницы ~= о_ресурсе_один;
	
	содержимоеГлавнойСтраницы ~= last_dekada;
	
	
	
	//содержимоеГлавнойСтраницы ~= table;
	
	
	tpl.set( "content", содержимоеГлавнойСтраницы );
	
	
	rp ~= tpl.getString();
}
