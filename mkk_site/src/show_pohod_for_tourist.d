module mkk_site.show_pohod_for_tourist;

import std.conv, std.string, std.utf, std.stdio;//  strip()       Уибират начальные и конечные пробелы   
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site.site_data, mkk_site.utils, mkk_site._import;

//Функция отсечки SQL иньекций.отсечь все символы кромье букв и -

//----------------------
immutable thisPagePath = dynamicPath ~ "show_pohod_for_tourist";

shared static this()
{	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
 	uint pageCount ; //Количество страниц
	uint curPageNum;
	      //= 1; //Номер текущей страницы
	uint offset=0; //Сдвиг по числу записей
	uint limit=5;// число строк на странице
	int число_походов;
	enum string [int] видТуризма=[0:"", 1:"пешеходный",2:"лыжный",3:"горный",
		4:"водный",5:"велосипедный",6:"автомото",7:"спелео",8:"парусный",
		9:"конный",10:"комбинированный" ];
	string vke;// вид туризма и категория сложности с элементыКС
	string  ps;//готовность и статус похода 
	auto rq = context.request;
	auto rp = context.response;

	bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	//writeln(1);
	string output; //"Выхлоп" программы
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
		
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		
		
	bool isTouristKeyAccepted;
	
	size_t touristKey;
	try {
		//Получаем ключ туриста из адресной строки
		touristKey = context.request.queryVars.get("key", null).to!size_t;
		isTouristKeyAccepted = true;
	}
	catch(std.conv.ConvException e)
	{	isTouristKeyAccepted = false; }
		
		string content ;//  содержимое страницы 
	
	
	content=`<h1> --------------------------------------------------------------</h1>`~ "\r\n";
	
	string qeri_ФИО = //по номеру в базе формируем строку ФИО г.р.
	`SELECT num,
(family_name||' '||coalesce(given_name,'')
||' '||coalesce(patronymic,'')||
 coalesce(birth_date,'')||', '||birth_year ) as birth_date
FROM tourist 
WHERE num=`~touristKey.to!string;
 
  string qeri_число_походов= //получаем число походов
  `select count(1) from (
 select unnest(pohod.unit_neim ) as u      
 FROM pohod ) as uu where uu.u =`~touristKey.to!string;
  

  
	alias FieldType ft;

   //получаем данные о ФИО и г.р. туриста
   auto touristRecFormat = RecordFormat!(
	 ft.IntKey, "Ключ",ft.Str, "Имя"	)();
	 
	 auto rs1 = dbase.query(qeri_ФИО).getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	 foreach(rec; rs1)
	 { content~=`<h1>` ~ rec.get!"Имя"("") ~ `</h1>`~ "\r\n";
	 }
	//-------------------------------------------------------------------
	//получаем данные о количестве походов
	
// 	 auto kolRecFormat = RecordFormat!(
// 	 ft.Int, "число_походов")();
	 
	 
	 auto кол_воПоходовРез_т = dbase.query(qeri_число_походов);
	 
    if( кол_воПоходовРез_т.recordCount )
    {
		content~=`<h2>` ~ кол_воПоходовРез_т.get(0, 0, "0")~` походов ` ~ `</h2>`~ "\r\n";
		число_походов=кол_воПоходовРез_т.get(0, 0, "0").to!int;
	 }
	 
	pageCount = (число_походов/limit)+1; //Количество страниц
	curPageNum = 1; //Номер текущей страницы
	
	try {
		if( "cur_page_num" in rq.postVars )
 			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }
	

	offset = (curPageNum -1) * limit ; //Сдвиг по числу записей
	content ~=`<form id="main_form" method="post">`;
	
		try { //Логирование запросов к БД для отладки
		std.file.append( eventLogFileName, 
			"--------------------\r\n"
			"Количество записей: " ~ число_походов.to!string ~ "\r\n"
			"Текущий номер страницы: "~ curPageNum.to!string ~ ", всего страниц: " ~ pageCount.to!string ~ "\r\n"
				);
	} catch(Exception) {}
	
	 if( (curPageNum > 0) && ( curPageNum <= pageCount ) ) 
	{	if( curPageNum != 1 )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a> `;
		
		content ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~
		`"  size="3"  maxlength="3"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `~ "\r\n";
		
		if( curPageNum != pageCount )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `~ "\r\n";
	}
	
	content ~= 
`	</form>
	<script type="text/javascript" src="` ~ js_file ~ `"></script>`~ "\r\n";
	 	//-------------------------------------------------------------------
	//образуем финальную таблицу
	
	auto pohodRecFormat = RecordFormat!(
	ft.IntKey, "Ключ",
	ft.Int, "турист",
	ft.Str, "Номер книги",
	ft.Str, "Сроки", 
	ft.Int, "Вид",
	ft.Int, "кс", ft.Int, "элем",	
	ft.Int,"Руководитель",
	ft.Str,"Город,<br>организация",
	ft.Str,"Район",   
	ft.Str, "Нитка маршрута",	
	ft.Int, "Готовность",ft.Int, "Статус"
	
	)();
	
	
	 string qeri_походы=//основной запрос
  `select * from (
 select
     pohod.num,
     unnest(pohod.unit_neim ) as u, 
     (coalesce(kod_mkk,'')||'<br>'||coalesce(nomer_knigi,'')) as nomer_knigi,   
(
    date_part('day', begin_date)||'.'||
    date_part('month', begin_date)||'.'||
    date_part('YEAR', begin_date)     
      ||' <br> '||
    date_part('day', finish_date)||'.'||
    date_part('month', finish_date)||'.'||
    date_part('YEAR', finish_date)
 ) as date ,  
      coalesce( vid, '0' ) as vid,
      coalesce( ks, '9' ) as ks,
      coalesce( elem, '0' ) as с_элементами,
      coalesce(chef_grupp,'0' ) as chef,     
     (coalesce(organization,'')||'<br>'||coalesce(region_group,'')) as organiz ,
     region_pohod ,     
     coalesce(marchrut::text,'') as marshrut, 
     coalesce(prepar,'0'),
     coalesce(stat,'0')
 FROM pohod order by  pohod.begin_date DESC ) as uu where uu.u =` ~touristKey.to!string
//~` order by  uu.begin_date DESC `//сортировка по дате в обратном порядке
 
 ~` LIMIT `~limit.to!string 
 ~` OFFSET `~offset.to!string 
 ~` `
 ;
	
	
	
	 auto rs2 = dbase.query(qeri_походы).getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	
	string table = `<table class="tab">`;
		
		if(_sverka) table~= `<td>Ключ</td>`;		
		table ~=`<td>&nbspНомер&nbsp</td>
		        <td>&nbsp&nbspСроки<br>похода&nbsp</td>
		        <td>Вид<br>кс</td>
		        <td>Район</td>
		        <td>Руков.<br>Участ.</td>		        
		        <td>Город,<br>организация</td>
		        <td>Статус<br> похода</td>`~ "\r\n";
		if(_sverka) table ~=`<td>Изменить</td>`~ "\r\n";
		
	foreach(rec; rs2)
	  
	{	
	   vke = видТуризма [rec.get!"Вид"(0)] ~ `<br>` ~ категорияСложности [rec.get!"кс"(0)] ~ `<br>` ~ элементыКС[rec.get!"элем"(0)] ;
	   ps  = готовностьПохода [rec.get!"Готовность"(0)] ~ `<br>` ~ статусЗаявки [rec.get!"Статус"(0)] ;
	  
	table ~= `<tr>`;  //Начинаем оформлять таблицу с данными
	  
		if(_sverka) table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`~ "\r\n";
		table ~= `<td >` ~rec.get!"Номер книги"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ rec.get!"Сроки"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~  vke ~ `</td>`~ "\r\n";//вид категорияСложности
		table ~= `<td>` ~  rec.get!"Район"("нет") ~ `</td>`~ "\r\n";
		table ~= `<td> `;
		if(rec.get!"турист"==rec.get!"Руководитель") {table ~= `Руков.`;}
		  else {table ~= `Участ.`;}
		                        table ~=`</td>`~ "\r\n";
		//руководство - участие
		table ~= `<td>` ~ rec.get!"Город,<br>организация"("нет")  ~ `</td>`~ "\r\n";		
		table ~= `<td>` ~ ps  ~ `</td>`;
		if(_sverka) table ~= `<td> <a href="#">Изменить</a>  </td>`~ "\r\n";
		table ~= `</tr>`~ "\r\n";
		table ~= `<tr>` ~ `<td style=";background-color:#8dc0de"    colspan="`~ "\r\n";
		if(_sverka)
		     table ~=`10`;
		  else
		     table ~=`8`;
		
		table ~= `"  >Нитка маршрута: ` ~ rec.get!"Нитка маршрута"("нет") ~ `</td>` ~ `</tr>`~ "\r\n";
	}
	table ~= `</table>`~ "\r\n";
	
	 
	content ~= table ~ "\r\n";
	content ~= `<script  type="text/JavaScript" src="pohod_filtr.js">  </script>` ~ "\r\n";
	


 
 
	
	auto tpl = getGeneralTemplate(thisPagePath);
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне
	//writeln(8);
	if( context.user.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.user.id );
	}
	else 
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}
	//writeln(9);
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

