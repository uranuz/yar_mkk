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
	string queryStr ;
	string fem = ( ( "fem" in rq.POST ) ? rq.POST["fem"] : "" ) ;
	string num_page = "15";
	string col_str;
	string col_page;
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
	
	col_str=`select count(1) from tourist`; 
	
	page=(col_page.to!int)/10+1;
	
	if(fem=="")
	
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
		   ` comment from tourist order by num LIMIT 10 OFFSET `~ num_page~` `;
		  
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
		   ` comment from tourist WHERE family_name='`~fem~`'  order by num `;   
		   
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
~`<form name="form1" method="post" action="show_tourist">
  <p>
    <label>Найти по фамилии
      <input name="fem" type="text" id="fem" size="32" `
     ~ ( ( fem.length > 0 ) ? ` value="` ~ fem ~ `"` : "" ) 
  ~  `>
    </label>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="button" id="button" value="Найти">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="hidden" name="num_page" value="`
  ~ num_page.to!string ~
  `">
  </p>
 
</form>
<form name="form2" method="post" action="baza_turistov.php">

 <input name="fem" type="hidden"    value=''>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
 
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <label>Показать всех
  <input type="submit" name="fam" id="fam" value=""></label>
 
</form>`


	
		~ table  ~ `</body></html>`; //превращаем RecordSet в строку html-кода
	output ~= html;
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		rp.write(output);
	}
}

