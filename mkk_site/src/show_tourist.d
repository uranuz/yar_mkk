module mkk_site.full_test;

import std.conv;

import webtank.datctrl.field_type;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
import webtank.net.application;


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
	
	string js_file = "../../js/page_view.js";
	
	string queryStr ;
	string fem = ( ( "fem" in rq.postVars ) ? rq.postVars["fem"] : "" ) ;
	uint limit = 10;
	int page;
	//try {
	//	num_page = rq.POST.get("num_page", "0");
	//} catch(Exception) { num_page = "0"; }
	
   string output; //"Выхлоп" программы
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
	
	string connStr = "dbname=baza_MKK host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if (dbase.isConnected) output ~= "Соединение с БД установлено";
	else  output ~= "Ошибка соединения с БД";
	
	//SELECT num, femelu, neim, otchectv0, brith_date, god, adrec, telefon, tel_viz FROM turistbl;
	
	auto col_str_qres = cast(PostgreSQLQueryResult) dbase.query(`select count(1) from tourist`);
	
	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	uint col_str = ( ( col_str_qres.getIsNull(0, 0) ) ? "0" : col_str_qres.getValue(0, 0) ).to!uint;
	
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
	
	if(filter=="")
	
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
		   ` comment from tourist WHERE family_name='`~filter~`'  order by num `;   
		   
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
	
	
	/*auto rsView = new RecordSetView(rs);
	rsView.outputModes.length = 6;
	with( FieldOutputMode )
		rsView.outputModes[0..$] = visible;
	rsView.viewManners.length = 6;
	rsView.viewManners[0..$] = FieldViewManner.plainText;*/
	string html = 
	`<html>`~ "\r\n"
	~`<meta http-equiv="Выберите расширение для парковки" content="text/html; charset=windows-1251">`~ "\r\n"
	~`<title>Список туристов</title>`~ "\r\n"
	~`<head><link rel="stylesheet" type="text/css" href="` 
	~`../../css/baza.css">`
	//~ projectPath 
	//~`/css/full_test.css">`
	~`</head>` ~ "\r\n"
	
	~`<body>`~ "\r\n"
	
	~`<h1><img src="/img/znak.png" width="130" height="121" alt="ТССР">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;База данных Ярославской МКК.   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</h1>  
<h2>Список туристов &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="show_pohod">Список походов</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="baza_glavnaya.php">Главная</a></h2>`~ "\r\n"
~
	`<form id="main_form" method="post">
		Фамилия: <input name="filter" type="text" value="` ~ filter ~ `">
		<input type="submit" name="act" value="Найти"><br>`;
	
	
	if( (curPageNum > 0) && ( curPageNum <= pageCount ) ) 
	{	if( curPageNum != 1 )
			html ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a> `;
		
		html ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~ `"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `;
		
		if( curPageNum != pageCount )
			html ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `;
	}
	
	html ~= 
`	</form>
	<script type="text/javascript" src="` ~ js_file ~ `"></script>`;

	html ~= table  ~ `</body></html>`; //превращаем RecordSet в строку html-кода
	output ~= html;
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		rp.write(output);
	}
}

