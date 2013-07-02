module mkk_site.full_test;

import std.conv;

import webtank.datctrl.field_type;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
import webtank.net.application;
import webtank.templating.plain_templater;


immutable(string) projectPath = `/webtank`;

Application netApp; //Обявление глобального объекта приложения

///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
}

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	string output; //"Выхлоп" программы
	string js_file = "../../js/page_view.js";
	
	//Создаём подключение к БД
	string connStr = "dbname=baza_MKK host=192.168.0.72 user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
	
	
	string fem = ( ( "fem" in rq.postVars ) ? rq.postVars["fem"] : "" ) ; 
	uint limit = 10;
	int page;
	
	
	auto col_str_qres = cast(PostgreSQLQueryResult) dbase.query(`select count(1) from tourist where`);
	
	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	uint col_str = ( col_str_qres.getValue(0, 0, "0") ).to!uint;
	
	uint pageCount = (col_str)/limit+1; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	try {
		if( "cur_page_num" in rq.postVars )
 			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }
	string filter = "";  //Фильтр поиска
	if( "filter" in rq.postVars ) 
		filter = rq.postVars.get("filter", "");
	
	uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	
	
	string content = 
	`<form id="main_form" method="post">
		Фамилия: <input name="filter" type="text" value="` ~ filter ~ `">
		<input type="submit" name="act" value="Найти"><br>`;
	
	
	if( (curPageNum > 0) && ( curPageNum <= pageCount ) ) 
	{	if( curPageNum != 1 )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a> `;
		
		content ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~ `"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `;
		
		if( curPageNum != pageCount )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `;
	}
	
	content ~= 
`	</form>
	<script type="text/javascript" src="` ~ js_file ~ `"></script>`;
	
   ///Начинаем оформлять таблицу с данными
	try {
	RecordFormat touristRecFormat; //объявляем формат записи таблицы book
	with(FieldType) {
	touristRecFormat = RecordFormat(
	[IntKey, Str, Str, Str, Str, Str],
	["Ключ", "Имя", "Дата рожд", "Опыт", "Контакты", "Комментарий"],
	//[null, null, null, null, null, null],
	[true, true, true, true, true, true] //Разрешение нулевого значения
	);
	}
	
	string queryStr;
	if( filter.length == 0 )
	
		queryStr=`select num, 
		(family_name||'<br>'||coalesce(given_name,'')||'<br>'||coalesce(patronymic,'')) as name, `
		`( coalesce(birth_date,'')||'<br>'||birth_year ) as birth_date , exp, `
		`( case `
			` when( show_phone = true ) then phone||'<br> ' `
			` else '' `
		` end || `
		` case `
			` when( show_email = true ) then email `
			` else '' `
		   ` end ) as contact, `
		   ` comment from tourist order by num LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `;
		  
   else
    
		queryStr=`select num, 
		(family_name||'<br>'||coalesce(given_name,'')||'<br>'||coalesce(patronymic,'')) as name, `
		`( coalesce(birth_date,'')||'<br>'||birth_year ) as birth_date , exp, `
		`( case `
			` when( show_phone = true ) then phone||'<br> ' `
			` else '' `
		` end || `
		` case `
			` when( show_email = true ) then email `
			` else '' `
		   ` end ) as contact, `
		   ` comment from tourist WHERE family_name='` ~ filter ~`'  order by num `;   
		   
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	string table = `<table>`;
	table ~= `<tr>`;
	table ~= `<td> Ключ</td><td>Имя</td><td> Дата рожд</td><td> Опыт</td><td> Контакты</td><td> Комментарий</td>`; 
	foreach(rec; rs)
	{	table ~= `<tr>`;
		table ~= `<td>` ~ ( ( rec["Ключ"].isNull() ) ? "Не задано" : rec["Ключ"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Имя"].isNull() ) ? "Не задано" : rec["Имя"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Дата рожд"].isNull() ) ? "Не задано" : rec["Дата рожд"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Опыт"].isNull() ) ? "Не задано" : rec["Опыт"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Контакты"].isNull() ) ? "Не задано" : rec["Контакты"].getStr() ) ~ `</td>`;
		
		table ~= `<td>` ~ ( ( rec["Комментарий"].isNull() ) ? "Не задано" : rec["Комментарий"].getStr() ) ~ `</td>`;
		
		table ~= `</tr>`;
	}
	table ~= `</table>`;
	
	content ~= table; //Тобавляем таблицу с данными к содержимому страницы
	
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
	tpl.set("img folder", "../../mkk_site/img/");
	tpl.set("css folder", "../../mkk_site/css/");
	tpl.set("cgi-bin", "/cgi-bin/mkk_site/");
	tpl.set("useful links", "Куча хороших ссылок");
	tpl.set("js folder", "../../mkk_site/js/");
	
	output ~= tpl.getResult(); //Получаем результат обработки шаблона с выполненными подстановками
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		rp.write(output);
	}
}

