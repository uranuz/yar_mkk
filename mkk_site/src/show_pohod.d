module mkk_site.show_pohod;

//Импорты стандартных модулей
import std.conv, std.file;

//Импорты из библиотеки webtank
import webtank.datctrl.field_type, webtank.db.postgresql, webtank.db.datctrl_joint,
webtank.datctrl.record, webtank.net.application, webtank.templating.plain_templater;

//Импорты модулей сайта МКК
import mkk_site.site_data;

static this()
{	Application.setHandler( &netMain, "/dynamic/show_pohod" ); 
	Application.setHandler( &netMain, "/dynamic/show_pohod/" ); 
}

immutable(string) projectPath = `/webtank`;

void netMain(Application netApp)  //Определение главной функции приложения
{	
	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	string output; //"Выхлоп" программы
	string js_file = "../../js/page_view.js";
	
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		
		string [10] v=["", "пеший","лыжный","горный","водный","велосипедный","автомото","спелео","парусный","конный" ];
		// виды туризма
		
		
		string [9] k=["", "н.к.","первая","вторая","третья","четвёртая","пятая","шестая","путешествие" ];
		// категории сложности
		
		 
		
		
		string vid = ( ( "vid" in rq.postVars ) ? rq.postVars["vid"] : "" ) ; 
		string[] ks = ( ( "ks" in rq.postVarsArray ) ? rq.postVarsArray["ks"] : null ) ; 
		string dat1 = ( ( "begin_data3" in rq.postVars ) ? rq.postVars["begin_data2"] : "" )~`-`
		            ~ ( ( "begin_data2" in rq.postVars ) ? rq.postVars["begin_data2"] : "" )~`-`
		            ~ `01`; 
	   string dat2 = ( ( "begin_data6" in rq.postVars ) ? rq.postVars["begin_data2"] : "" )~`-`
		            ~ ( ( "begin_data5" in rq.postVars ) ? rq.postVars["begin_data5"] : "01" )~`-`
		            ~ `01`; 
		  auto long_ks= ks.length;         
		string all_ks;
		foreach( kkkk; ks )
			all_ks ~= kkkk;
		            
		immutable(string) LogFile = "/home/test_serv/sites/test/logs/mkk_site.log";            
		   try { //Логирование запросов к БД для отладки
	std.file.append( LogFile, 
		"--------------------\r\n"
		"ks " ~ long_ks.to!string ~"  "~ all_ks ~ "\r\n"
	);
	} catch(Exception) {}         
		
		// Запрос на число строк
	//	auto col_str_qres = ( fem.length == 0 ) ? cast(PostgreSQLQueryResult) dbase.query(`select count(1) from pohod` ):
	//cast(PostgreSQLQueryResult) dbase.query(`select count(1) from tourist where family_name = '` ~ fem ~ "'");
	
		uint limit = 10;// максимальное  чмсло строк на странице
	   int page;
	
	
	try {
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
	
	
	string tablefiltr = `  <form id="main_form" method="post">
	<table border="1" >`;
	
	tablefiltr ~=`<tr> <td> "Вид туризма" </td> 
	     <td>
	     <select name="vid" size="1">`;
// 	     foreach( i; 0..10 )
	     for( int i=0; i<10;i++)
	     tablefiltr ~=`<option value="`~v[i] ~`"`~
	     ( ( v[i]==vid ) ? " selected": "" )//если условие выполняется возвращается(вклеивается) selected
	     ~`>`~v[i]~`</option>`;
	     
	  tablefiltr ~= `</td>`;
	       
	      
	 	//rq.postVarsArray[] формирует ассоциативный массив массивов из строки возвращаемой по пост запросу     
	     
	      
	tablefiltr ~=` <td> "Категория сложности"</td>
	
	<td>
	     <select name="ks" size="3" multiple>
	     <option value='' selected></option>
	     <option value='н.к.'selected >н.к.</option>
	     <option value='первая'selected >первая </option>
	     <option value='вторая' >вторая</option>
	     <option value='третья' >третья</option>
	     <option value='четвёртая' >четвёртая</option>
	     <option value='пятая' >пятая</option>
	     <option value='шестая' >шестая</option>
	     <option value='путешествие' >путешествие</option>
	         
	          < /select >
	      </td> 
	</tr>`;
	tablefiltr ~=`<tr> <td> "Время начала похода ( с)" </td>
	<td>
	 
	 <input neim="begin_data2" type="text" value="" size="2" maxlength="2"> месяц
	 <input neim="begin_data3" type="text" value="" size="4" maxlength="4"> год
	</td>  `;
	tablefiltr ~=`<td> "Время начала похода ( по)" </td>  
	<td>
	 
	 <input neim="begin_data5" type="text" value="" size="2" maxlength="2"> месяц
	 <input neim="begin_data6" type="text" value="" size="4" maxlength="4"> год 
	</td> </tr>`;
	
	  tablefiltr ~= `</table>`;
	  //------------------------------------кнопки-----------------------------------
	 string buton= `
	
	 
	 <input width="2000"type="submit" neim="button1" value="&nbsp;&nbsp;&nbsp;&nbsp; Найти &nbsp;&nbsp;&nbsp;">
	                
	 </form> 
	 
	 
	     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	            <form id="main_form" method="post">
	            
	            
	                <input width="2000"type="submit" neim="button2" value="Показать всё">
	                <input neim="vid" type="hidden" value="">
	                <input neim="ks[]" type="hidden" value="">
	                <input neim="begin_data2" type="hidden" value="">
	                <input neim="begin_data3" type="hidden" value="">
	                <input neim="begin_data5" type="hidden" value="">
	                <input neim="begin_data6" type="hidden" value="">
	               
	                
	             </form>   
	                `;
	            
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
	
	string content = tablefiltr ~`<p>&nbsp</p>`~buton~`<p>&nbsp</p>`~table; //Тобавляем таблицу с данными к содержимому страницы
	
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
	
	output ~= tpl.getResult(); //Получаем результат обработки шаблона с выполненными подстановками
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		rp.write(output);
	}
}

