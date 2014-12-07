module mkk_site.show_tourist;

import std.conv, std.string, std.utf;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context;

import webtank.net.utils;

import mkk_site;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_tourist";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;

	bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	
	//Создаём подключение к БД
	auto dbase = getCommonDB();

	string raz_sud_kat;
	
	string fem = PGEscapeStr( rq.bodyForm.get("family_name", null) ); // пропускаем фамилию через функцию отсечки

	uint limit = 10;// максимальное  чмсло строк на странице

	auto col_str_qres = // запрос на число строк
		fem.length == 0 ? dbase.query(`select count(1) from tourist` )://без фильтра
		dbase.query(`select count(1) from tourist where family_name ILIKE '%`~ fem ~ `%'`);
	//с фильтром фамилией
  
	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	
	uint col_str = ( col_str_qres.get(0, 0, "0") ).to!uint;// количество строк 
	
	uint pageCount = (col_str)/limit+1; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	
	//-----------------------
	try {
		if( "cur_page_num" in rq.bodyForm )// если в окне задан номер страницы
 			curPageNum = rq.bodyForm["cur_page_num"].to!uint;
 			
	} catch (Exception) {}
	
	//-------------
	if(curPageNum>pageCount) curPageNum=pageCount; 
	//если номер страницы больше числа страниц переходим на последнюю 
	//?? может лучше на первую
	
	uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	string content = 
	`<form id="main_form" method="post">
		Фамилия: <input name="family_name" type="text" value="` ~ fem ~ `">
		<input type="submit" name="act" value="Найти"><br>`~ "\r\n";

	if( (curPageNum > 0) && ( curPageNum <= pageCount ) ) 
	{	if( curPageNum != 1 )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a> `;
		
		content ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~ `" size="3"  maxlength="3" > из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `~ "\r\n";
		
		if( curPageNum != pageCount )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `~ "\r\n";
	}
	
	content ~= `</form><br/>`;
	
	import std.typecons;
	
   ///Начинаем оформлять таблицу с данными
   static immutable touristRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Имя и год рожд", 
		string,  "Опыт", 
		string, "Контакты",
		typeof(спортивныйРазряд),  "Разряд", 
		typeof(судейскаяКатегория), "Категория",
		string, "Комментарий"
	)(
		null,
		tuple(спортивныйРазряд, судейскаяКатегория)
	);
	
	string queryStr =
`select 
	num, 
	( 
		coalesce(family_name, '') ||
		coalesce(' ' || given_name, '') ||
		coalesce(' ' || patronymic, '') ||
		coalesce(', ' || birth_year::text, '') 
	) as name,
	coalesce(exp, '???'), 
	( 
		case 
			when( show_phone = true ) then phone||'<br> ' 
		else '' end || 
		case 
			when( show_email = true ) then email 
		else '' end 
	) as contact,
	razr, sud, comment 
from tourist `
	~ ( fem.length == 0 ? "" : ` WHERE family_name ILIKE '%` ~ fem ~"%'" ) 
	~ ` order by num LIMIT `~ limit.to!string ~ ` OFFSET `~ offset.to!string ~` `; 
		   
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	string table = `<div style="max-width: 98%;"><table class="tab1">`~ "\r\n";
	
	table ~= `<tr>`;
	if(_sverka) table ~= `<th>#</th>`~ "\r\n";
	
	table ~=`<th width="20%">Имя, дата рожд.</th><th>Опыт</th>
	<th>Спорт. разряд, cуд. категория</th><th>Комментарий</th>`~ "\r\n";

	if(_sverka) table ~=`<th>Изм.</th>`~ "\r\n";
	table ~= `<tr>`;
	
	foreach(rec; rs)
	{	
		raz_sud_kat= rec.getStr!"Разряд"() ~ `<br>` ~ rec.getStr!"Категория"() ~ "\r\n";
		
		table ~= `<tr>`;
		if(_sverka) table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`~ "\r\n";
		table ~= `<td width="20%" >` ~ HTMLEscapeText( rec.get!"Имя и год рожд"("") ) ~ `</td>`~ "\r\n";
		table ~= `<td>`
		~ `<a href="` ~ dynamicPath ~ `show_pohod_for_tourist?key=` ~ rec.get!"Ключ"(0).to!string ~ `">`
		~ rec.get!"Опыт"("")  ~ ` </a></td>`~ "\r\n";
		
		table ~= `<td>` ~ raz_sud_kat ~ `</td>` ~ "\r\n";
		table ~= `<td>` ~ HTMLEscapeText(rec.get!"Комментарий"("нет")) ~ `</td>`~ "\r\n";
		if(_sverka) 
			table ~= `<td> <a href="` ~ dynamicPath ~ `edit_tourist?key=` ~ rec.get!"Ключ"(0).to!string ~ `">Изм.</a>  </td>`~ "\r\n";
		
		table ~= `</tr>`~ "\r\n";
	}
	
	table ~= `</table></div>`~ "\r\n";

	if(_sverka) content ~= `<a href="edit_tourist" >Добавить нового туриста</a>`~ "\r\n";
	
	content ~= table; //Тобавляем таблицу с данными к содержимому страницы
	
	return content;
}

