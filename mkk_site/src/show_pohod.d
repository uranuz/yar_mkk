module mkk_site.show_pohod;

import std.stdio;
import std.conv, std.string, std.array;
import std.file; //Стандартная библиотека по работе с файлами
//import webtank.db.database;
import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint,webtank.datctrl.record, webtank.net.http.routing, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site.site_data, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "show_pohod";

shared static this()
{	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
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
		
		string vke;
		
		string ps;
		
	enum string [int] видТуризма=[0:"", 1:"пешеходный",2:"лыжный",3:"горный",
		4:"водный",5:"велосипедный",6:"автомото",7:"спелео",8:"парусный",
		9:"конный",10:"комбинированный" ];
		// виды туризма
	/*			
	enum	string [int] категорияСложности=[ 0:"н.к.",1:"первая",2:"вторая",3:"третья",4:"четвёртая",5:"пятая",6:"шестая",
		7:"путешествие",8:"любая",9:"ПВД" ,10:"" ];
		// категории сложности
	enum	string [int] элементыКС=[0:"",1:"с эл.1",2:"с эл.2",3:"с эл.3",4:"с эл.4",5:"с эл.5",6:"с эл.6"];
		
	enum	string [int] готовностьПохода=[0:"",1:"планируется",2:"набор группы",3:"набор завершён",4:"идёт подготовка",
		5:"на маршруте",6:"пройден",7:"пройден частично",8:"не пройден"];
		
	enum	string [int] статусЗаявки=[0:"",1:"не заявлен",2:"подана заявка",3:"отказ в заявке",4:"заявлен",
		5:"засчитан",6:"засчитан частично",7:"не засчитан"];
		*/
		
		string[] month =["","январь","февраль","март","апрель","май","июнь",
		       "июль","август","сентябрь","октябрь","ноябрь","декабрь"];
		
		bool _vid;    // наличие фильтрации вид туризма
		bool _ks;    //  наличие фильтрации категория сложности
		bool _start_dat; // наличие начального диапазона поиска
		bool _end_dat;   // наличие конечного  диапазона поиска
		bool _filtr;    // котроль необходимости фильтрации
		bool _sverka = context.accessTicket.isAuthenticated && ( context.accessTicket.user.isInGroup("admin") || context.accessTicket.user.isInGroup("moder") );    // наличие сверки
		///////////////////////////////
		string vid = ( ( "vid" in rq.postVars ) ? rq.postVars["vid"] : "0" ) ;// вид туризма		
		if (vid=="0") _vid=false;
		else _vid=true;
		////////////////////
		string[] ks = ( ( "ks" in rq.postVarsArray ) ? rq.postVarsArray["ks"] : null ) ; // категория сложности похода		
		//  strip()       Убирает начальные и конечные пробелы   
		auto long_ks= ks.length;// выдаёт число элементов массива         
		//string all_ks;
		foreach( kkkk; ks )// перебирает элементы массива
		    { 
		    if (kkkk=="8"||kkkk=="10") {_ks=false;break; }
		    else _ks=true;
		     }
		
		//////////////////////////////////
		
		
		
		string s_year  = ( ( "start_year"  in rq.postVars ) ? rq.postVars["start_year"] : "" );// начальный год диапазона поиска		
		string s_month = ( ( "start_month" in rq.postVars ) ? rq.postVars["start_month"] : "");// начальный месяц диапазона поиска                                      
		if ( s_year=="") _start_dat=false;                  // наличие начального диапазона поиска если начального года нет "запрещено"
		else _start_dat=true;
		//----------------------формирование начала диапозона дат
		string s_dat;   // начальная дата диапозона поиска
		if(_start_dat)
		
		s_dat =s_year.to!string ~`-`;   // если месяц указан сформировать значение маска 2013-05-01
		if(s_month!="")
		{foreach( i, word; month)
		{	if( s_month == word ) 
			{	 if(i<9)s_dat ~=`0`; // если месяц меньше 10-го добавить 0 перед номером (сдвиг по значению на 1)
			
			s_dat ~= i.to!string ~`-01`; //-01 первое число месяца
				break;
			}
		}
		}
		 else {s_dat ~=`01-01`;} // если месяца нет искать с первого января текущего года
	
	  ///////////////////////////////////// 
	   string e_year  = ( ( "end_year"  in rq.postVars ) ? rq.postVars["end_year"] : "" ); // конечный год диапазона поиска
		string e_month = ( ( "end_month" in rq.postVars ) ? rq.postVars["end_month"] : ""); // конечный месяц диапазона поиска
		
				
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
		      e_dat =e_year.to!string ~`-`;		
		     foreach( i, word; month)
		     {	if( e_month == word ) 
			      {  if(i<9) e_dat ~=`0`; 
					      	e_dat ~= (i+1).to!string ~`-01`;// добавляем единицу к номеру месяца для включение этого месяца в диапазон
			    	break;}
	      	}
		   }
	    }
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
				if (_ks)	select_str2 ~=" and ";}
				
	if (_ks)
	{	select_str2 ~= " ( ";
		foreach( n, kkkk; ks ) 
		{	select_str2 ~= ` ks='` ~kkkk~`'`~ ( (  n+1 < long_ks ) ? " OR ": "" );// перебирает элементы массива ks
		 }
		select_str2 ~= " ) ";
		select_str2~=((_start_dat) || (_end_dat))?" and ": "";
		
	}	
		
	// фильтрация по дате
	
	
  	if ((s_year !="")&&(e_year =="")) select_str2 ~= `  begin_date>='` ~ s_dat~`' `;  	
	if ((s_year =="")&&(e_year !="")) select_str2 ~= `  begin_date<= '` ~e_dat~`' `;
 	if ((s_year !="")&&(e_year !="")) select_str2 ~= `  (begin_date>='`~ s_dat~`' and `~ `begin_date <='`~e_dat~`') `;
 	select_str2~=`) `;
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
	
	uint pageCount = (col_str)/limit+1; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	try {
		if( "cur_page_num" in rq.postVars )
 			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }

	uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	
	
	alias FieldType ft;
	
	
	auto pohodRecFormat = RecordFormat!(
	ft.IntKey, "Ключ",   ft.Str, "Номер книги", ft.Str, "Сроки", 
	ft.Int, "Вид", ft.Int, "кс", ft.Int, "элем",
	//ft.Str,"Руководитель", 
	//ft.Str,"Участники", 
	ft.Str,"Город,<br>организация",
	ft.Str,"Район",
	ft.Str, "Нитка маршрута",
	ft.Int, "Готовность",ft.Int, "Статус")();
	//WHERE
	
	string queryStr = 
	`with 
tourist_nums as (
  select num, unnest(unit_neim) as tourist_num from pohod
),  `

   `  tourist_info as (
select tourist_nums.num, tourist_num, family_name, given_name, patronymic, birth_year from tourist_nums
  join tourist 
   on tourist_num = tourist.num
), `

`U as (

select num, string_agg(
  family_name||' '||coalesce(given_name,'')||' '||coalesce(patronymic,'')||' '||coalesce(birth_year::text,''), chr(13) 
  ) as gr
from tourist_info
group by num
) `

	  `select pohod.num, (coalesce(kod_mkk,'')||'<br>'||coalesce(nomer_knigi,'')) as nomer_knigi, `  
     `(
    date_part('day', begin_date)||'.'||
    date_part('month', begin_date)||'.'||
    date_part('YEAR', begin_date) 

    
      ||' <br> '||
    date_part('day', finish_date)||'.'||
    date_part('month', finish_date)||'.'||
    date_part('YEAR', finish_date)
 ) as date , ` 
     ` coalesce( vid, '0' ),coalesce( ks, '9' ),coalesce( elem, '0' ) ,`

     `region_pohod , `
     `(tourist.family_name||'<br> '||coalesce(tourist.given_name,'')||'<br> '||coalesce(tourist.patronymic,'')||'<br> '||coalesce(tourist.birth_year::text,'')), `
     `(coalesce(pohod.unit,'')),(coalesce(gr,'')), `
     
     `(coalesce(organization,'')||'<br>'||coalesce(region_group,'')), `
     `(coalesce(marchrut::text,'')||'<br>'||coalesce(chef_coment::text,'')), `
     `coalesce(prepar,'0'),
        coalesce(stat,'0')  `
             `from pohod `
               
        ` JOIN tourist   `
      `on pohod.chef_grupp = tourist.num `
      ` LEFT OUTER JOIN  U `
      `on U.num = pohod.num  `;     
      
		if( _filtr ){	queryStr~=select_str2;}	
		
		queryStr~=` order by  pohod.begin_date DESC  LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `;
	
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	

	
	//uint aaa = cast(uint) rs.recordCount;
	//output ~= aaa.to!string;
	
	
	string tablefiltr = `<table border="1" >`;
	
	tablefiltr ~=`<tr> <td> "Вид туризма" </td> 
	     <td>
	     <select name="vid" size="1">`;
// 	     foreach( i; 0..10 )
	     for( int i=0; i<11;i++)
	     tablefiltr ~=`<option value=`~i.to!string ~` `~
	     ( ( i==vid.to!int ) ? " selected": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~`>`~видТуризма[i]~`</option>`;
	     
	  tablefiltr ~= `</select> </td>`;
	       
	      
	 	//rq.postVarsArray[] формирует ассоциативный массив массивов из строки возвращаемой по пост запросу     
	     
	      
	tablefiltr ~=` <td> "Категория сложности"</td>
	
	<td>
	     <select name="ks" size="3" multiple>`;
	     
	      for( int i=0; i<11;i++)
	      
	      {tablefiltr ~=`<option value=`~i.to!string  ~`  `;
	     
	                for( int j=0;j<long_ks;j++) {if(i==ks[j].to!int) tablefiltr ~=`selected` ; }//если условие выполняется возвращается(вклеивается) selected
	                                     
	    
	    tablefiltr ~=`>`~категорияСложности[i]~`</option>`; }
	 
	    
	         
	      tablefiltr ~=  `< /select >`;    
	      
	   tablefiltr ~= `</td>`;
	tablefiltr ~= `</tr>`;
	
	
	tablefiltr ~=`<tr> <td> "Время начала похода ( с)" </td>
	<td>`;
	//окно первы месяц диапазона
	tablefiltr ~=` <select name="start_month" size="1" >`;
	  for( int i=0; i<13;i++)
	  tablefiltr ~=`<option value="`~month[i] ~`"`~
	     ( ( month[i]==s_month ) ? " selected ": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~` >`~month[i]~`</option>`;
	     
	  tablefiltr ~= `</select> `;    
	 
	 // окно первый год диапазона
	 tablefiltr ~=`<input name="start_year" type="text" value="`~ s_year ~`" size="4" maxlength="4"> год	</td>  `;
	 
	 
	 
	tablefiltr ~=`<td> "Время начала похода ( по)" </td>  
	<td>`;
	
	//окно последний месяц диапазона 
	tablefiltr ~=`<select name="end_month" size="1" >`;
	  for( int i=0; i<13;i++)
	  tablefiltr ~=`<option value="`~month[i] ~`"`~
	     ( ( month[i]==e_month ) ? " selected ": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~` >`~month[i]~`</option>`;	     
	  tablefiltr ~= `</select>`;
	  
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
	</tr>
	
	
	`;
	//pageCount номер страницы
	 
	  tablefiltr ~= "</table>\r\n";
	  //------------------------------------конец формирования-tablefiltr----------------------------------
	string pageSelector = `<table><tr><td style='width: 100px;'>`
	~ ( (curPageNum > 1) ? `<a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a>` : "" )
	
	~"</td><td>"
	~` Страница <input name="cur_page_num" type="text" size="4" maxlength="4" value="` ~ curPageNum.to!string ~ `"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `
	~"</td><td>"
	
	~  ( (curPageNum < pageCount ) ? `<a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a>` : "")
	~"</td></tr></table>";
	 
	    // _sverka=true;    // наличие сверки     
	    
	    
	    
		string table = `<table class="tab">`;
		
		if(_sverka) table~= `<td>Ключ</td>`;
		
		table ~=`<td>&nbspНомер&nbsp</td><td>&nbsp&nbspСроки<br>похода&nbsp</td><td> Вид<br>кс</td><td >Район</td><td>Руководитель</td><td>Участники</td><td>Город,<br>организация</td><td>Статус<br> похода</td>`;
		if(_sverka) table ~=`<td>Изменить</td>`;
	foreach(rec; rs)
	  
	{	
	   vke = видТуризма [rec.get!"Вид"(0)] ~ `<br>` ~ категорияСложности [rec.get!"кс"(0)] ~ `<br>` ~ элементыКС[rec.get!"элем"(0)] ;
	   ps  = готовностьПохода [rec.get!"Готовность"(0)] ~ `<br>` ~ статусЗаявки [rec.get!"Статус"(0)] ;
	  
	table ~= `<tr>`;
	  
		if(_sverka) table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`;
		table ~= `<td >` ~rec.get!"Номер книги"("нет")  ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Сроки"("нет")  ~ `</td>`;
		table ~= `<td>` ~  vke ~ `</td>`;
		table ~= `<td >` ~ rec.get!"Район"("нет") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Руководитель"("нет")  ~ `</td>`;
		
		table ~= `<td style="text-align: center;" title="`~ rec.get!"Уч"("нет")~`">` ~`<font color="red">`~  (  rec.get!"Участники"("Не задано") ) ~ `</font ></td>`;
		
		
		table ~= `<td>` ~ rec.get!"Город,<br>организация"("нет")  ~ `</td>`;

		table ~= `<td>` ~ ps  ~ `</td>`;
		if(_sverka) table ~= `<td> <a href="#">Изменить</a>  </td>`;
		table ~= `</tr>`;
		table ~= `<tr>` ~ `<td style=";background-color:#8dc0de"    colspan="`;
		if(_sverka)
		table ~=`10`;
		else
		table ~=`8`;
		
		table ~= `"  >Нитка маршрута: ` ~ rec.get!"Нитка маршрута"("нет") ~ `</td>` ~ `</tr>`;
	}
	table ~= `</table>`;
	
	string content = `<form id="main_form" method="post">`
	~ tablefiltr ~ pageSelector ~ `</form><br><br>`~table; //Тобавляем таблицу с данными к содержимому страницы
	
	//Создаем шаблон по файлу
	auto tpl = getGeneralTemplate(thisPagePath);
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне

	if( context.accessTicket.isAuthenticated )
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.accessTicket.user.name ~ "</b>!!!</i>");
		tpl.set("user login", context.accessTicket.user.login );
	}
	else 
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}
	
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

