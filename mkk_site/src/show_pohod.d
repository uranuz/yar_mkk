module mkk_site.show_pohod;

import std.stdio;
import std.conv, std.string, std.array;
import std.file; //Стандартная библиотека по работе с файлами
//import webtank.db.database;
import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint,webtank.datctrl.record, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site.site_data, mkk_site.utils, mkk_site._import;
import mkk_site.site_data, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "show_pohod";

shared static this()
{	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(participantsList);
}

string participantsList( size_t pohodNum )
{	writeln("participantsList ", "номерПохода: ", pohodNum);
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null;
	
	auto рез_запроса = dbase.query(`with tourist_nums as (
select unnest(unit_neim) as num from pohod where pohod.num = ` ~ pohodNum.to!string ~ `
)
select coalesce(family_name, '')||coalesce(' '||given_name,'')
||coalesce(' '||patronymic, '')||coalesce(', '||birth_year::text,'') from tourist_nums 
left join tourist
on tourist.num = tourist_nums.num
	`);
	
	auto поход = dbase.query( `select (coalesce(kod_mkk , '')
	||' Маршрутка № '||coalesce( nomer_knigi, 'нет сведений') 
	||'.<br> Район проведения '||coalesce(region_pohod, '')) as poh from pohod where pohod.num = ` ~ pohodNum.to!string ~ ` `);
	
	string result;//список туристов
	result ~= поход.get(0, 0, null) ~ `<br>---------------------------------------<br>`;
	
	
	if( рез_запроса.recordCount<1) result ~=`Сведения об участниках <br> отсутствуют`;
	else
	   {
	      for( size_t i = 0; i < рез_запроса.recordCount; i++ )
	           {	result ~= рез_запроса.get(0, i, "") ~ `<br>`;	}
	   }        
	           
	return result;
	
	
}




void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	//---------------------------
	string output; //"Выхлоп" программы 
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
	//------------------------------------
	
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		
		string параметры_поиска;//контроль изменения парамнтров фильтрации
		string параметры_поиска_старое= rq.postVars.get("параметры_поиска", "");
		
		string vke;//сводная строка видТуризма категорияСложности сэлементами кс
		
		string ps;//сводная строка готовностьПохода статусЗаявки
		
	enum string [int] видТуризма=[0:"", 1:"пешеходный",2:"лыжный",3:"горный",
		4:"водный",5:"велосипедный",6:"автомото",7:"спелео",8:"парусный",
		9:"конный",10:"комбинированный" ];
		// виды туризма
	
		
		string[] month =["","январь","февраль","март","апрель","май","июнь",
		       "июль","август","сентябрь","октябрь","ноябрь","декабрь"];
		
		bool _vid;    // наличие фильтрации вид туризма
		bool _ks;    //  наличие фильтрации категория сложности
		bool _start_dat; // наличие начального диапазона поиска
		bool _end_dat;   // наличие конечного  диапазона поиска
		bool _filtr;    // котроль необходимости фильтрации
		bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
		///////////////////////////////
		string vid = ( ( "vid" in rq.postVars ) ? rq.postVars["vid"] : "0" ) ;// вид туризма		
		if (vid=="0") _vid=false;
		else _vid=true;
		////////////////////
		string[] ks = ( ( "ks" in rq.postVarsArray ) ? rq.postVarsArray["ks"] : null ) ; // категория сложности похода		
		  
		auto long_ks= ks.length;// выдаёт число элементов массива - выбранные категории Сложности походов       
		
		foreach( kkkk; ks )// перебирает элементы массива
		    { 
		    if (kkkk=="8"||kkkk=="10") {_ks=false;break; }
		    else _ks=true;
		     }
		
		//////////////////////////////////
		
	   string e_year  = ( ( "end_year"  in rq.postVars ) ? rq.postVars["end_year"] : "" );
	   // конечный год диапазона поиска
		string e_month = ( ( "end_month" in rq.postVars ) ? rq.postVars["end_month"] : "");
		// конечный месяц диапазона поиска		
		string s_year  = ( ( "start_year"  in rq.postVars ) ? rq.postVars["start_year"] : "" );// начальный год диапазона поиска		
		string s_month = ( ( "start_month" in rq.postVars ) ? rq.postVars["start_month"] : "");// начальный месяц диапазона поиска   
		//writeln(e_year,e_month,s_year,s_month);
		
		if ( s_year=="") _start_dat=false;                  // наличие начального диапазона поиска если начального года нет "запрещено"
		else _start_dat=true;
		//----------------------формирование начала диапозона дат
		string s_dat;   // начальная дата диапозона поиска
		if(_start_dat)  // если сушествует год начала поиска 
		                //формируем значение по маске 2013-05-01
{	
	       s_dat =s_year.to!string ~`-`; // добавляем 2013- (взятое из окна - запроса s_year)
		
		if(s_month!="")// если месяц указан сформировать значение маска 2013-05-01

	{
		  foreach( i, word; month)
			if( s_month == word ) 
			{	 if(i<10)s_dat ~=`0`; // если месяц меньше 10-го добавить 0 перед номером (сдвиг по значению на 1)
			
			s_dat ~= i.to!string ~`-01`; //-01 первое число месяца
				break;
			}	
			}
		else {s_dat ~=`01-01`;} // если месяца нет искать с первого января текущего года
		
		 

}	
	//writeln(s_dat);
	  ///////////////////////////////////// 
	  
		
				
		if ( e_year=="") _end_dat=false;  // наличие конечного диапазона поиска если конечного года нет "запрещено"
		else _end_dat=true;
		//----------------------формирование конца диапозона дат
		string e_dat; // конечная дата диапозона поиска
		
		if(_end_dat)
		{
		
		      if((e_month=="декабрь")||(e_month=="")) // если месяц  декабрь или  пустой ставим дату с начала следующего года
		        {e_dat =(e_year.to!int+1).to!string ~`-01-01`;}
		
		      else		 
		   {
		      e_dat =e_year.to!string ~`-`;	// записываем год поиска например 2013-	
		     foreach( i, word; month)
		     // ищем индекс месяца начиная с 1 и до 12 из массива month
		     {	if( e_month == word ) 
			      {  if(i<10) e_dat ~=`0`; // если номер однозначный добавляем перед значением 0
					      	e_dat ~= (i+1).to!string ~`-01`;// добавляем единицу к номеру месяца для включение этого месяца в диапазон
			    	break;}
	      	}
		   }
	    }
	   // writeln(e_dat);
		////////////////////////////////////////////////////////////
		
		
	
		
		
		
		_filtr=_start_dat||_end_dat||_ks||_vid;//переменная отвечающшая за необходимость фильтрации (true есть фильтрация)
		
		
		//-----------------------------            
		immutable(string) LogFile = "/home/test_serv/sites/test/logs/mkk_site.log";            
		   try { //Логирование запросов к БД для отладки
	std.file.append( LogFile, 
		"--------------------\r\n"
		"вид туризма vid - " ~ vid
		~ " ks категория - " ~ join(ks, "/")
		
		~ "\r\n"
	);
	} catch(Exception) {}         
	 //----------------------------------------------------------	
	
	
	параметры_поиска=`Вид-`~vid~` с-`~s_dat~` по-`~e_dat~` кс`;
	
	//параметры_поиска~=ks.to!string;
	
	foreach (r;ks){ параметры_поиска~=`-`~r.to!string;     }
	//writeln(параметры_поиска);
	
	uint limit = 5;// максимальное  число строк на странице
	int page;
	//-----------------формируем варианты запросов на число строк-------------------------
	string select_str1 =`select count(1) from pohod`; 	// при отсутствии фильтрации 
	string select_str2;
	
	// формируем расширеенный запрос строки 153 - 194
	if(_filtr)
	{
	select_str2=` where (`;
	if (_vid)
	
	        {select_str2~= ` vid='`~vid~`' `;// добавлние запроса по виду туризма
				if (_ks)	select_str2 ~=` and `;}
				
	if (_ks)
	{	select_str2 ~= ` ( `;
		foreach( n, kkkk; ks ) 
		{	select_str2 ~= ` ks='` ~kkkk~`'`~ ( (  n+1 < long_ks ) ? ` OR `: ` ` );// перебирает элементы массива ks
		 }
		select_str2 ~= ` ) `;
		select_str2~=((_start_dat) || (_end_dat))?` and `: ` `;
		
	}	
		
	// фильтрация по дате
	
	
  	if ((s_year !="")&&(e_year =="")) select_str2 ~= `  begin_date>='` ~ s_dat~`' `; 
  	// есть начальная дата 	
	if ((s_year =="")&&(e_year !="")) select_str2 ~= `  begin_date<= '` ~e_dat~`' `;
	// есть конечная дата
 	if ((s_year !="")&&(e_year !="")) select_str2 ~= `  (begin_date>='`~ s_dat~`' and `~ `begin_date <='`~e_dat~`') `;// есть обе даты
 	select_str2~=` ) `;
 	
 	}
 			//----------- конец формировки расширеенного  запроса--------------------------
	
	string select_str= select_str1 ~ select_str2; // полный запрос
	
	try { //Логирование запросов к БД для отладки
	std.file.append( LogFile, 
		"--------------------\r\n"
		"select_str: " ~ select_str ~ "\r\n"
		"s_dat: " ~ e_dat.to!string ~ "\r\n"
	);
	} catch(Exception e) {}     
	
	
	auto col_str_qres = 	dbase.query(select_str);
	
	
	
	
	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	uint col_str = ( col_str_qres.get(0, 0, "0") ).to!uint;
	
	uint pageCount = (col_str-1)/limit+1; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	
	////////////////
	try {
		if( "cur_page_num" in rq.postVars )// если в окне задан номер страницы
 			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }
	/////////
	if(curPageNum>pageCount) curPageNum=pageCount; 
	//если номер страницы больше числа страниц переходим на последнюю 
	//?? может лучше на первую

	if(параметры_поиска_старое!=параметры_поиска)curPageNum=1;
	//если параметры поиска изменились переходим н 1-ю страницу
	
	uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	
	
	alias FieldType ft;
	
	
	auto pohodRecFormat = RecordFormat!(
	ft.IntKey, "Ключ",   ft.Str, "Номер книги", ft.Str, "Сроки", 
	ft.Int, "Вид", ft.Int, "кс", ft.Int, "элем",
	ft.Str,"Район",
	ft.Str,"Руководитель", 
	ft.Str, "Число участников",
	ft.Str,"Город,<br>организация",	
	ft.Str, "Нитка маршрута",
	ft.Int, "Готовность",
	ft.Int, "Статус")();
	//WHERE
	
	string queryStr = // основное тело запроса
	`with 
t_chef as (
 select pohod.num,/*номер похода*/
         
        (
    coalesce(T.family_name,'нет данных')||'<br> '
  ||coalesce(T.given_name,'')||'<br> '
  ||coalesce(T.patronymic,'')||'<br>'
  ||coalesce(T.birth_year::text,'')
        ) as fio  
 /* создаётся таблица номера руководителей похода - их ФИО г.р.*/

from pohod
 LEFT join tourist T
   on pohod.chef_grupp = T.num
)


	  select pohod.num,
   (coalesce(kod_mkk,'')||'<br>'||coalesce(nomer_knigi,'')) as nomer_knigi,   
     (
    date_part('day', begin_date)||'.'||
    date_part('month', begin_date)||'.'||
    date_part('YEAR', begin_date) 
    
      ||' <br> '||
    date_part('day', finish_date)||'.'||
    date_part('month', finish_date)||'.'||
    date_part('YEAR', finish_date)
     ) as dat ,  
      coalesce( vid, '0' ) as vid,
      coalesce( ks, '9' ) as ks,
      coalesce( elem, '0' ) as elem,

     region_pohod , 
     t_chef.fio , 
     (coalesce(pohod.unit,'')) as kol_tur,
     /*(coalesce(gr,'')) as gr, */
     
     (coalesce(organization,'')||'<br>'||coalesce(region_group,'')) as organiz, 
     (coalesce(marchrut::text,'')||'<br>'||coalesce(chef_coment::text,'')) as marchrut, 
     coalesce(prepar,'0') as prepar,
        coalesce(stat,'0') as stat 
             from pohod 
               
       

       LEFT OUTER JOIN t_chef
      on t_chef.num = pohod.num  `;     
      
		if( _filtr ){	queryStr~=select_str2;}	// добавляем фильтрации
		
		queryStr~=` order by  pohod.begin_date DESC  LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `;
	
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	

	

	
	string tablefiltr ;// таблица фильтрации и кнопок
	
	tablefiltr = `<input name="параметры_поиска"  type="hidden" value="`~параметры_поиска~`" />`~ "\r\n";
	
	tablefiltr ~= `<table border="1" >`~ "\r\n";
	
	tablefiltr ~=`<tr> <td> "Вид туризма" </td> 
	     <td>
	     <select name="vid" size="1">`;
// 	     foreach( i; 0..10 )
	     for( int i=0; i<11;i++)
	     tablefiltr ~=`<option value=`~i.to!string ~` `~
	     ( ( i==vid.to!int ) ? " selected": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~`>`~видТуризма[i]~`</option>`;
	     
	  tablefiltr ~= `</select> </td>`~ "\r\n";
	       
	  	tablefiltr ~=` <td> "Категория сложности"</td>
	
	<td>
	     <select name="ks" size="3" multiple>`~ "\r\n";
	     
	      for( int i=0; i<11;i++)
	      
	      {tablefiltr ~=`<option value=`~i.to!string  ~`  `;
	     
	                for( int j=0;j<long_ks;j++) {if(i==ks[j].to!int) tablefiltr ~=`selected` ; }//если условие выполняется возвращается(вклеивается) selected
	                                     
	    
	    tablefiltr ~=`>`~категорияСложности[i]~`</option>`; }
	 
	           
	      tablefiltr ~=  `< /select >`~ "\r\n";    
	      
	   tablefiltr ~= `</td>`;
	tablefiltr ~= `</tr>`~ "\r\n";
	
	tablefiltr ~=`<tr> <td> "Время начала похода ( с)" </td>
	<td>`;
	//окно первы месяц диапазона
	tablefiltr ~=` <select name="start_month" size="1" >`;
	  for( int i=0; i<13;i++)
	  tablefiltr ~=`<option value="`~month[i] ~`"`~
	     ( ( month[i]==s_month ) ? " selected ": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~` >`~month[i]~`</option>`;
	     
	  tablefiltr ~= `</select> `~ "\r\n";    
	 
	 // окно первый год диапазона
	 tablefiltr ~=`<input name="start_year" type="text" value="`~ s_year ~`" size="4" maxlength="4"> год	</td>  `~ "\r\n";
		 
	 
	tablefiltr ~=`<td> "Время начала похода ( по)" </td>  
	<td>`~ "\r\n";
	
	//окно последний месяц диапазона 
	tablefiltr ~=`<select name="end_month" size="1" >`~ "\r\n";
	  for( int i=0; i<13;i++)
	  tablefiltr ~=`<option value="`~month[i] ~`"`~
	     ( ( month[i]==e_month ) ? " selected ": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~` >`~month[i]~`</option>`;	     
	  tablefiltr ~= `</select>`~ "\r\n";
	  
	  // окно последниий год диапазона
	 tablefiltr ~=`<input name="end_year" type="text" value="`~e_year~`" size="4" maxlength="4"> год 
	</td> </tr>
	<tr>
	     <td>
	      <input type="submit" neim="button1" value="&nbsp;&nbsp;&nbsp;&nbsp; Найти &nbsp;&nbsp;&nbsp;">       
	      </td>
	      <td> </td>
	      <td>  </td>
	      <td>
	      <a href="` ~ thisPagePath ~`" > <input type="button" value="&nbsp;&nbsp;&nbsp;Показать всё!&nbsp;&nbsp;&nbsp;"> </a>
       </td>
	</tr>	`~ "\r\n";
	//pageCount номер страницы
	 
	  tablefiltr ~= "</table>"~ "\r\n";
	  //--------------------------------конец формирования -tablefiltr-------------------------------
	  /////////////////////////////////////////////////////////////////////////////////////////////
	  
	  // окна выбора страницы
	string pageSelector = `<table><tr><td style='width: 100px;'>`
	~ ( (curPageNum > 1) ? `<a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a>` : "" )
	
	~"</td><td>"~ "\r\n"
	~` Страница <input name="cur_page_num" type="text" size="4" maxlength="4" value="` ~ curPageNum.to!string ~ `"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `
	~"</td><td>"~ "\r\n"
	
	~  ( (curPageNum < pageCount ) ? `<a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a>` : "")
	~"</td></tr></table>"~ "\r\n";
	 
	    // _sverka=true;    // наличие сверки     
	    
	    
	  // Начало формирования основной отображающей таблицы  
		string table = `<table class="tab">`;
		
		if(_sverka) table~= `<td>Ключ</td>`~ "\r\n";// появляется при наличии допуска
		
		table ~=`<td>&nbspНомер&nbsp</td><td>&nbsp&nbspСроки<br>похода&nbsp</td><td> Вид<br>кс</td><td >Район</td><td>Руководитель</td><td>Участники</td><td>Город,<br>организация</td><td>Статус<br> похода</td>`~ "\r\n";
		if(_sverka) table ~=`<td>Изменить</td>`~ "\r\n";// появляется при наличии допуска
	foreach(rec; rs)
	  
	{	
	   vke = видТуризма [rec.get!"Вид"(0)] ~ `<br>` ~ категорияСложности [rec.get!"кс"(0)] ~ `<br>` ~ элементыКС[rec.get!"элем"(0)] ;
	   ps  = готовностьПохода [rec.get!"Готовность"(0)] ~ `<br>` ~ статусЗаявки [rec.get!"Статус"(0)] ;
	  
	table ~= `<tr>`;
	  
		if(_sverka) table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`~ "\r\n";// появляется при наличии допуска
		table ~= `<td >` ~rec.get!"Номер книги"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ rec.get!"Сроки"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~  vke ~ `</td>`~ "\r\n";
		table ~= `<td >` ~ rec.get!"Район"("нет") ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ rec.get!"Руководитель"("нет")  ~ `</td>`~ "\r\n";
		
		table ~= `<td  class="show_participants_btn"  style="text-align: center;" >`~ "\r\n" 
		~ (  rec.get!"Число участников"("Не задано") ) ~ `<img src="` ~imgPath~`icons/list_icon.png">`
		~ `	<input type="hidden" value="`~rec.get!"Ключ"(0).to!string~`"> 
		</td>`~ "\r\n";
		
		
		table ~= `<td>` ~ rec.get!"Город,<br>организация"("нет")  ~ `</td>`~ "\r\n";

		table ~= `<td>` ~ ps  ~ `</td>`~ "\r\n";
		if(_sverka) table ~= `<td> <a href="#">Изменить</a>  </td>`~ "\r\n";// появляется при наличии допуска
		table ~= `</tr>`~ "\r\n";
		table ~= `<tr>` ~ `<td style=";background-color:#8dc0de"    colspan="`;
		if(_sverka)
		table ~=`10`;
		else
		table ~=`8`;
		
		table ~= `"  >Нитка маршрута: ` ~ rec.get!"Нитка маршрута"("нет") ~ `</td>` ~ `</tr>`~ "\r\n";
	}
	table ~= `</table>`~ "\r\n";
	// конец формирования основной таблицы
	
	string content;
	
	content ~= `<link rel="stylesheet" type="text/css" href="` ~ cssPath ~ `page_styles.css">`;
	
	content ~= `<form id="main_form" method="post">`// содержимое страницы
	~ tablefiltr ~ pageSelector ~ `</form><br><br>`~ "\r\n"
	~`<h1> Число походов `~col_str.to!string ~` </h1>`~ "\r\n"
	~table; //Тобавляем таблицу с данными к содержимому страницы
	
	content ~= `<script src="`~ jsPath ~ "show_pohod.js" ~ `"></script>`;
	
	//Создаем шаблон по файлу
	auto tpl = getGeneralTemplate(thisPagePath);
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне

	if( context.user.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.user.id );
	}
	else 
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}
	
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

