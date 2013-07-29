module mkk_site.show_tourist;

//Импорты стандартных модулей
import std.conv, std.file;

//Импорты из библиотеки webtank
import webtank.datctrl.field_type, webtank.db.postgresql, webtank.db.datctrl_joint,
webtank.datctrl.record, webtank.net.application, webtank.templating.plain_templater;

//Импорты модулей сайта МКК
import mkk_site.site_data;

immutable(string) projectPath = `/webtank`;
immutable(string) LogFile = "/home/test_serv/sites/test/logs/mkk_site.log";

static this()
{	Application.setHandler( &netMain, "/dynamic/show_tourist" ); 
	Application.setHandler( &netMain, "/dynamic/show_tourist/" ); 
}

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	string output; //"Выхлоп" программы
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
	
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
	
	//rq.postVarsArray[] формирует ассоциативный массив массивов из строки возвращаемой по пост запросу
	
	string fem = ( ( "family_name" in rq.postVars ) ? rq.postVars["family_name"] : "" ) ; 

	try { //Логирование запросов к БД для отладки
	std.file.append( LogFile, 
		"--------------------\r\n"
		"Фамилия: " ~ fem ~ "\r\n"
	);
	} catch(Exception) {}
	uint limit = 10;// максимальное  чмсло строк на странице
	int page;
	auto col_str_qres = ( fem.length == 0 ) ? cast(PostgreSQLQueryResult) dbase.query(`select count(1) from tourist` ):
	cast(PostgreSQLQueryResult) dbase.query(`select count(1) from tourist where family_name = '` ~ fem ~ "'");
	
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
	
	
	
	string content = 
	`<form id="main_form" method="post">
		Фамилия: <input name="family_name" type="text" value="` ~ fem ~ `">
		<input type="submit" name="act" value="Найти"><br>`;
	
	try { //Логирование запросов к БД для отладки
		std.file.append( LogFile, 
			"--------------------\r\n"
			"Количество записей: " ~ col_str.to!string ~ "\r\n"
			"Текущий номер страницы: "~ curPageNum.to!string ~ ", всего страниц: " ~ pageCount.to!string ~ "\r\n"
		);
	} catch(Exception) {}
	
	
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
	if( fem.length == 0 )
	
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
		   ` comment from tourist WHERE family_name='` ~ fem ~`'  order by num LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `;   
		   
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	string table = `<table border="1">`;
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
	import std.stdio;
	auto f = File( generalTemplateFileName, "r" );
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

