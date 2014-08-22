module mkk_site.show_pohod_for_tourist;

import std.conv, std.string, std.utf, std.typecons;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site;

//Функция отсечки SQL иньекций.отсечь все символы кромье букв и -

//----------------------
immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_pohod_for_tourist";
	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
 	uint pageCount ; //Количество страниц
	uint curPageNum;
	      //= 1; //Номер текущей страницы
	uint offset=0; //Сдвиг по числу записей
	uint limit=5;// число строк на странице
	int число_походов;

	string vke;// вид туризма и категория сложности с элементыКС
	string  ps;//готовность и статус похода 
	auto rq = context.request;
	auto rp = context.response;

	bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	string output; //"Выхлоп" программы
	scope(exit) rp.write(output);

		
	//Создаём подключение к БД
	auto dbase = getCommonDB();
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		
		
	bool isTouristKeyAccepted;
	
	size_t touristKey;
	try {
		//Получаем ключ туриста из адресной строки
		touristKey = context.request.queryForm.get("key", null).to!size_t;
		isTouristKeyAccepted = true;
	}
	catch(std.conv.ConvException e)
	{	isTouristKeyAccepted = false; }
		
	string content;//  содержимое страницы 
	
	
	content=`<hr>`~ "\r\n";
	
	string qeri_ФИО = //по номеру в базе формируем строку ФИО г.р.
`
SELECT 
	num,
	(	
		coalesce(family_name, '') ||
		coalesce(' ' || given_name, '') ||
		coalesce(' ' || patronymic, '') ||
		coalesce(', ' || birth_year::text, '') 
	) as birth_date,
	coalesce(exp,'не определён') as opt,
	razr, sud,
	(	case 
			 when( show_phone = true ) then phone||'<br> ' 
			else '' 
		end || 
		case 
			 when( show_email = true ) then email 
			 else '' 
		   end 
	) as contact, 
	comment
 
FROM tourist 
WHERE num =` ~touristKey.to!string;
 
  string qeri_число_походов = //получаем число походов
  `select count(1) from (
 select unnest(pohod.unit_neim ) as u      
 FROM pohod ) as uu where uu.u =`~touristKey.to!string;
  

   //получаем данные о ФИО и г.р. туриста
   static immutable touristRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Имя, день рожд", 
		string, "Опыт", 
		typeof(спортивныйРазряд), "Разряд", 
		typeof(судейскаяКатегория), "Категория",
		string, "Контакты",
		string, "Комментарий"
	)(
		null,
		tuple(
			спортивныйРазряд,
			судейскаяКатегория
		)
	);
	 
	 auto rs1 = dbase.query(qeri_ФИО).getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	 foreach(rec; rs1)
	 { 
		content ~= `<h1>` ~ rec.get!"Имя, день рожд"("") ~ `</h1>`~ "\r\n"
			~ `<p>Туристский опыт: ` ~ rec.get!"Опыт"("не известно/см. список") ~ `</p>` ~ "\r\n"
			~ `<p>Спортивный разряд: ` ~ rec.getStr!"Разряд"("не известно") ~ `</p>` ~ "\r\n"
			~ `<p>Судейская категория: ` ~ rec.getStr!"Категория"("не известно") ~ `</p>` ~ "\r\n"
			~ `<p>Контакты: `~ rec.get!"Контакты"("нет")  ~ `</p><br>` ~ "\r\n"
			~ `<p>Коментарий:</p> <p>`~ rec.get!"Комментарий"("")  ~ `</p><br>`~ "\r\n";
	 }
	//-------------------------------------------------------------------
	//получаем данные о количестве походов
	
// 	 auto kolRecFormat = RecordFormat!(
// 	 ft.Int, "число_походов")();
	 
	 
	 auto кол_воПоходовРез_т = dbase.query(qeri_число_походов);
	 
    if( кол_воПоходовРез_т.recordCount )
    {
		content~=`<h2> Походов ` ~ кол_воПоходовРез_т.get(0, 0, "0")~` </h2>`~ "\r\n";
		число_походов=кол_воПоходовРез_т.get(0, 0, "0").to!int;
	 }
	 
	pageCount = (число_походов/limit)+1; //Количество страниц
	curPageNum = 1; //Номер текущей страницы
	
	try {
		if( "cur_page_num" in rq.bodyForm )
 			curPageNum = rq.bodyForm.get("cur_page_num", "1").to!uint;
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
	
	content ~= `</form>` ~ "\r\n";
	
	static immutable pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ",
		int, "турист",
		string, "Номер книги",
		string, "Сроки", 
		typeof(видТуризма), "Вид",
		typeof(категорияСложности), "кс",
		typeof(элементыКС), "элем",
		int, "Руководитель",
		string, "Город, организация",
		string, "Район",   
		string, "Нитка маршрута",
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
	
	
	 string qeri_походы=//основной запрос
`
select * from (
	select
		pohod.num,
		unnest(pohod.unit_neim ) as u, 
		(coalesce(kod_mkk,'000-00')||'<br>'||coalesce(nomer_knigi,'00-00')) as nomer_knigi,   
		(
			date_part('day', begin_date)||'.'||
			date_part('month', begin_date)||'.'||
			date_part('year', begin_date)     
			||' <br> '||
			date_part('day', finish_date)||'.'||
			date_part('month', finish_date)||'.'||
			date_part('year', finish_date)
		) as date,  
		vid,
		ks,
		elem,
		chef_grupp,     
		( coalesce(organization,'') || '<br>' || coalesce(region_group,'') ) as organiz ,
		region_pohod,     
		coalesce(marchrut::text,'') as marshrut, 
		prepar,
		stat
	FROM pohod order by pohod.begin_date DESC 
) as uu 
where uu.u =` ~ touristKey.to!string
	~ ` LIMIT ` ~ limit.to!string 
	~ ` OFFSET ` ~ offset.to!string 
	~ ` `
	;
	
	auto rs2 = dbase.query(qeri_походы).getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	
	string table = `<table class="tab1">`;
	
	table ~= "<tr>";
	if(_sverka) table~= `<th>#</th>`;
	table ~=`<th>№ книги</th>
				<th>Сроки похода</th>
				<th>Вид, категория</th>
				<th>Район</th>
				<th>Руков., участ.</th>
				<th>Город, организация</th>
				<th>Статус похода</th>` ~ "\r\n";
	if(_sverka) table ~=`<th>Изменить</th>`~ "\r\n";
	table ~= "</tr>";
		
	foreach(rec; rs2)
	{	
	   vke = rec.getStr!"Вид"() ~ `<br>` ~ rec.getStr!"кс"() ~ `<br>` ~ rec.getStr!"элем"() ;
	   ps  = rec.getStr!"Готовность"() ~ `<br>` ~ rec.getStr!"Статус"();
	   
	  
		table ~= `<tr>`;  //Начинаем оформлять таблицу с данными
		
		if(_sverka) 
			table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`~ "\r\n";// появляется при наличии допуска
	  
		table ~= `<td> <a href="` ~ dynamicPath ~ `pohod?key=`
			~ rec.get!"Ключ"(0).to!string ~ `">` ~ rec.get!"Номер книги"("нет") ~`</a>  </td>`~ "\r\n";
		
		table ~= `<td>` ~ rec.get!"Сроки"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~  vke ~ `</td>`~ "\r\n";//вид категорияСложности
		table ~= `<td>` ~  rec.get!"Район"("нет") ~ `</td>`~ "\r\n";
		table ~= `<td> `;
		if( rec.get!"турист" == rec.get!"Руководитель" ) 
			table ~= `Руков.`;
		else
			table ~= `Участ.`;
		
		table ~= `</td>` ~ "\r\n";
		//руководство - участие
		table ~= `<td>` ~ rec.get!"Город, организация"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ ps  ~ `</td>`;
		
		if(_sverka)
			table ~= `<td> <a href="` ~ dynamicPath ~ `edit_pohod?key=`
				~ rec.get!"Ключ"(0).to!string ~ `">Изменить</a>  </td>`~ "\r\n";// появляется при наличии допуска
		
		table ~= `</tr>` ~ "\r\n";
		table ~= `<tr>` ~ `<td style="background-color:#8dc0de;"    colspan="`~ "\r\n";
		if(_sverka)
		     table ~=`10`;
		else
		     table ~=`8`;
		
		table ~= `">Нитка маршрута: ` ~ rec.get!"Нитка маршрута"("нет") ~ `</td>` ~ `</tr>`~ "\r\n";
	}
	table ~= `</table>`~ "\r\n";
	
	 
	content ~= table ~ "\r\n";
	content ~= `<script  type="text/JavaScript" src="pohod_filtr.js">  </script>` ~ "\r\n";
	
	auto tpl = getGeneralTemplate(context);
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне

	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

