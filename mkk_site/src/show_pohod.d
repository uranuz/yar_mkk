module mkk_site.show_pohod;

import std.stdio;
import std.conv, std.string;
import std.file; //Стандартная библиотека по работе с файлами
//import webtank.db.database;
import webtank.datctrl.field_type;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
import webtank.net.application;
import webtank.templating.plain_templater;

import mkk_site.site_data;

static this()
{	Application.setHandler(&netMain, dynamicPath ~ "show_pohod");
	Application.setHandler(&netMain, dynamicPath ~ "show_pohod/");
}

immutable(string) projectPath = `/webtank`;

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	string output; //"Выхлоп" программы
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
	
	//Создаём подключение к БД
	string connStr = "dbname=baza_MKK host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		
		string [10] v=["", "пеший","лыжный","горный","водный","велосипедный","автомото","спелео","парусный","конный" ];
		// виды туризма
		
		
		string [9] k=["любая", "н.к.","первая","вторая","третья","четвёртая","пятая","шестая","путешествие" ];
		// категории сложности
		
		//int [string] month =[0:"","январь":1,"февраль":2,"март":3,"апрель":4,"май":5,"июнь":6,
		     //  "июль":7,"август":8,"сентябрь":9,"октябрь":10,"ноябрь":11,"декабрь":12];
		     
		 string[] month =["","январь","февраль","март","апрель","май","июнь",
		       "июль","август","сентябрь","октябрь","ноябрь","декабрь"];     
		
		
		
		
		string vid = ( ( "vid" in rq.postVars ) ? rq.postVars["vid"] : "" ) ; 
		string[] ks = ( ( "ks" in rq.postVarsArray ) ? rq.postVarsArray["ks"] : null ) ; 
		 
		string s_year  = ( ( "start_year"  in rq.postVars ) ? rq.postVars["start_year"] : "" );
		string s_month = ( ( "start_month" in rq.postVars ) ? rq.postVars["start_month"] : "");
	
		string start_dat =  s_year ~ s_month; 
		
		string s_dat =s_year.to!string ~`-`;		
		foreach( i, word; month)
		{	if( s_month == word ) 
			{	 if(i<10)s_dat ~=`0`;  s_dat ~= i.to!string ~`-01`;
				break;
			}
		}
		 
	   
	   string e_year  = ( ( "end_year"  in rq.postVars ) ? rq.postVars["end_year"] : "" );
		string e_month = ( ( "end_month" in rq.postVars ) ? rq.postVars["end_month"] : "");
		string end_dat = e_year ~ e_month;
		string e_dat;
		if(e_month!="декабрь")
		{
		 e_dat =e_year.to!string ~`-`;		
		foreach( i, word; month)
		{	if( e_month == word ) 
			{	 if(i<10) e_dat ~=`0`;  e_dat ~= (i+1).to!string ~`-01`;
				break;
			}
		}
		}
		
		else		 e_dat =(e_year.to!int+1).to!string ~`-01-01`;		
		
		
		
		
		//  strip()       Убирает начальные и конечные пробелы   
		auto long_ks= ks.length;// выдаёт число элементов массива         
		string all_ks;
		foreach( kkkk; ks ) all_ks ~= kkkk;// перебирает элемкнты массива
			 
			 
		string nou_filtr; // котроль необходимости фильтрации
		nou_filtr= s_year ~ e_month ~ s_year ~ s_month ~ vid ~ all_ks;
		
		
		            
		immutable(string) LogFile = "/home/test_serv/sites/test/logs/mkk_site.log";            
		   try { //Логирование запросов к БД для отладки
	std.file.append( LogFile, 
		"--------------------\r\n"
		"год переменная " ~ vid~"год окно  "~  all_ks ~ "\r\n"
	);
	} catch(Exception) {}         
		
		// Запрос на число строк
	//	auto col_str_qres = ( fem.length == 0 ) ? cast(PostgreSQLQueryResult) dbase.query(`select count(1) from pohod` ):
	//cast(PostgreSQLQueryResult) dbase.query(`select count(1) from tourist where family_name = '` ~ fem ~ "'");
	
	
	
	
	uint limit = 2;// максимальное  число строк на странице
	int page;
	//-----------------формируем варианты запросов на число строк-------------------------
	string select1 =`select count(1) from pohod`; 	// при отсутствии фильтрации
	string select_str =`select count(1) from pohod where`;
	
	
	if (vid.length !=0) select_str~= ` vid='`~vid~`' `;
	
	
	bool isAnyKs = false;// булева перемеенная  отвечающая за  фильтрацию  по признаку категории ссложности
	
	if (long_ks != 0 )
	{	foreach(kkkk; ks)
		if( kkkk == "любая" )
		{	isAnyKs = true;
			break;
		}
	}
	else
		isAnyKs = true;
	
	if( !isAnyKs )
	{	foreach(kkkk; ks)
			if( kkkk == "любая" )
			{	isAnyKs = true;
				break;
			}
			
		if (vid.length !=0  )	select_str ~=" and ";
	
		select_str ~= " ( ";
		foreach( n, kkkk; ks ) 
			select_str ~= ` ks='` ~kkkk~`'`~ ( (  n+1 < long_ks ) ? " OR ": "" );// перебирает элементы массива
		select_str ~= " ) ";
	}
	
	select_str~=((s_year !="") || (e_year !=""))?" and ": "";
	
  	if ((s_year !="")&&(e_year =="")) select_str ~= `  begin_date<='` ~s_dat~`' `;
  	
	if ((s_year =="")&&(e_year !="")) select_str ~= `  end_dat>'` ~e_dat~`' `;
 	if ((s_year !="")&&(e_year !="")) select_str ~= `  (begin_date>'`~s_dat~`' and `~`begin_date <='`~e_dat~`') `;
	
	
	try { //Логирование запросов к БД для отладки
	std.file.append( LogFile, 
		"--------------------\r\n"
		"select_str: " ~ select_str ~ "\r\n"
		"s_dat: " ~ end_dat.to!string ~ "\r\n"
	);
	} catch(Exception) {}     
	
	
	auto col_str_qres = ( nou_filtr.length == 0 ) ? cast(PostgreSQLQueryResult) dbase.query(select1 ):
	cast(PostgreSQLQueryResult) dbase.query(select_str);
	
	
	
	
	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	uint col_str = ( col_str_qres.getValue(0, 0, "0") ).to!uint;
	
	uint pageCount = (col_str)/limit+1; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	try {
		if( "cur_page_num" in rq.postVars )
 			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }

	uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	
	
	
	
	
	RecordFormat touristRecFormat; //объявляем формат записи таблицы book
	with(FieldType) {
	touristRecFormat = RecordFormat(
	[IntKey, Str, Str, Str, Str, Str, Str, Str, Str, Str, Str],
	["Ключ", "Номер", "Сроки <br> похода", "Вид, кс","Район","Руководитель","Участники","Уч","Город,<br>организация", "Нитка маршрута","Статус<br> похода"],
	//[null, null, null, null, null, null,null, null, null],
	[true, true, true, true, true, true, true, true,true, true, true] //Разрешение нулевого значения
	);
	}
	

	
	
	
	
	
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
     `(coalesce(begin_date::text,'')||'<br>'||coalesce(finish_date::text,'')) as date , ` 
     `( coalesce( vid::text, '' )||'<br>'|| coalesce( ks::text, '' )||coalesce( element::text, ' ' ) ) as vid,`

     `region_pohod , `
     `(tourist.family_name||'<br>'||coalesce(tourist.given_name,'')||'<br>'||coalesce(tourist.patronymic,'')||'<br>'||coalesce(tourist.birth_year::text,'')), `
     `(coalesce(pohod.unit,'')),(coalesce(gr,'')), `
     
     `(coalesce(organization,'')||'<br>'||coalesce(region_group,'')), `
     `(coalesce(marchrut::text,'')||'<br>'||coalesce(chef_coment::text,'')), `
     `(coalesce(prepare::text,'')||'<br>'||coalesce(status::text,''))  `
             `from pohod  `
               
        ` JOIN tourist   `
      `on pohod.chef_grupp = tourist.num `
      ` LEFT OUTER JOIN  U `
      `on U.num = pohod.num order by pohod.num `        

;
		
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	//uint aaa = cast(uint) rs.recordCount;
	//output ~= aaa.to!string;
	
	
	string tablefiltr = `  <form id="main_form" method="post"  inline >
	<table border="1" >`;
	
	tablefiltr ~=`<tr> <td> "Вид туризма" </td> 
	     <td>
	     <select name="vid" size="1">`;
// 	     foreach( i; 0..10 )
	     for( int i=0; i<10;i++)
	     tablefiltr ~=`<option value="`~v[i] ~`"`~
	     ( ( v[i]==vid ) ? " selected": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~`>`~v[i]~`</option>`;
	     
	  tablefiltr ~= `</select> </td>`;
	       
	      
	 	//rq.postVarsArray[] формирует ассоциативный массив массивов из строки возвращаемой по пост запросу     
	     
	      
	tablefiltr ~=` <td> "Категория сложности"</td>
	
	<td>
	     <select name="ks" size="3" multiple>`;
	     
	      for( int i=0; i<9;i++)
	      
	      {tablefiltr ~=`<option value="`~k[i] ~`" `;
	     
	                for( int j=0;j<long_ks;j++) {if(k[i]==ks[j]) tablefiltr ~=`selected` ; }//если условие выполняется возвращается(вклеивается) selected
	                                     
	    
	    tablefiltr ~=`>`~k[i]~`</option>`; }
	 
	    
	         
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
	        <input type="submit" value="&nbsp;&nbsp;<<&nbsp;Назад &nbsp;&nbsp;&nbsp;">
	      </td>
	      <td>
	      
	       страница `~curPageNum.to!string~`из `~ pageCount.to!string~ 
	       
	      `</td>
	      <td>
	       
	       перейти на 
	       <input name="str" type="text" value="" size="4" maxlength="4">
	       <input type="submit" value="&nbsp;&nbsp;&nbsp;Вперёд&nbsp;>>&nbsp;&nbsp;">
	       
	       
	       </form>
	       
	      </td>
	      <td>
	      <form > <input type="submit" value="&nbsp;&nbsp;&nbsp;Показать всё!&nbsp;&nbsp;&nbsp;"></form>
       </td>
	</tr>
	`;
	//pageCount номер страницы
	 
	  tablefiltr ~= "</table>\r\n";
	  //------------------------------------конец формирования-tablefiltr----------------------------------
	 
	          
	            
		string table = `<table border="1">`;
		
		table ~= `<td>"Ключ"</td><td> "Номер"</td><td> "Сроки <br> похода"</td><td> "Вид, кс"</td><td>"Район"</td><td>"Руководитель"</td><td>"Участники"</td><td>"Город,<br>организация"</td><td> "Нитка маршрута"</td><td>"Статус<br> похода"</td>`;
	foreach(rec; rs)
	{	table ~= `<tr>`;
	  
		table ~= `<td>` ~ ( ( rec["Ключ"].isNull() ) ? "Не задано" : rec["Ключ"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Номер"].isNull() ) ? "Не задано" : rec["Номер"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Сроки <br> похода"].isNull() ) ? "Не задано" : rec["Сроки <br> похода"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Вид, кс"].isNull() ) ? "Не задано" : rec["Вид, кс"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Район"].isNull() ) ? "Не задано" : rec["Район"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Руководитель"].isNull() ) ? "Не задано" : rec["Руководитель"].getStr() ) ~ `</td>`;
		
		table ~= `<td  title="`~ ( ( rec["Уч"].isNull() ) ? "Не задано" : rec["Уч"].getStr() )~`">` ~`<font color="red">`~  ( ( rec["Участники"].isNull() ) ? "Не задано" : rec["Участники"].getStr() ) ~ `</font ></td>`;
		
		
		table ~= `<td>` ~ ( ( rec["Город,<br>организация"].isNull() ) ? "Не задано" : rec["Город,<br>организация"].getStr() ) ~ `</td>`;
		
		
	
		table ~= `<td>` ~ ( ( rec["Нитка маршрута"].isNull() ) ? "Не задано" : rec["Нитка маршрута"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Статус<br> похода"].isNull() ) ? "Не задано" : rec["Статус<br> похода"].getStr() ) ~ `</td>`;
		table ~= `<td> <a href="#">Изменить</a>  </td>`;
		table ~= `</tr>`;
	}
	table ~= `</table>`;
	
	string content = tablefiltr ~`<p>&nbsp</p>`~`<p>&nbsp</p>`~table; //Тобавляем таблицу с данными к содержимому страницы
	
	//Чтение шаблона страницы из файла
	string templFileName = "/home/test_serv/web_projects/mkk_site/templates/general_template.html";
	import std.stdio;
	auto f = File(templFileName, "r");
	string templateStr; //Строка с содержимым файла шаблона страницы 
	string buf;
	while ((buf = f.readln()) !is null)
		templateStr ~= buf;
		
	//Создаем шаблон по файлу
	auto tpl = new PlainTemplater( templateStr );
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне
	//Задаём местоположения всяких файлов
	tpl.set("img folder", "../../img/");
	tpl.set("css folder", "../../css/");
	tpl.set("cgi-bin", "/cgi-bin/mkk_site/");
	tpl.set("useful links", "Куча хороших ссылок");
	tpl.set("js folder", "../../js/");
	
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

