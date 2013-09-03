module mkk_site.full_test;

import std.conv, std.string, std.utf;//  strip()       Уибират начальные и конечные пробелы   
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.field_type;
import webtank.datctrl.record_format;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
import webtank.net.application;
import webtank.templating.plain_templater;

import mkk_site.site_data;

//Функция отсечки SQL иньекций.отсечь все символы кромье букв и -
string nou_SQL_injekt(string str)
{
dstring dstr = toUTF32(str);
dstring dstr1;
for (int i=0;i<dstr.length;i++)
{
if(dstr[i]==' ' ||  dstr[i]=='-' || dstr[i]=='_' || dstr[i]=='(' || dstr[i]==')' || (dstr[i]>='A' && dstr[i]<'Z'  ) || (dstr[i]>='a' && dstr[i]<='z'  ) ||
(dstr[i]>='А' && dstr[i]<='я' ) || dstr[i]=='Ё' || dstr[i]=='ё' )
dstr1~=dstr[i];
//допустимые  символы А-Я,а-я,A-Z,f-z,-,_,),(.
}
//  strip()       Уибират начальные и конечные пробелы

string result = strip(toUTF8(dstr1));
return result;
}
//----------------------

static this()
{	Application.setHandler(&netMain, thisPagePath );
	Application.setHandler(&netMain, thisPagePath ~ "/");
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
	   
	string fem = nou_SQL_injekt( ( ( "family_name" in rq.postVars ) ? rq.postVars["family_name"] : "" ) ); 
	
 
   
	try { //Логирование запросов к БД для отладки
	std.file.append( eventLogFileName, 
		"--------------------\r\n"
		"Фамилия: " ~ fem ~ "\r\n"
	);
	} catch(Exception) {}
	uint limit = 10;// максимальное  чмсло строк на странице
	int page;
	auto col_str_qres = ( fem.length == 0 ) ? dbase.query(`select count(1) from tourist` ):
	dbase.query(`select count(1) from tourist where family_name = '` ~ fem ~ "'");
	
	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	uint col_str = ( col_str_qres.get(0, 0, "0") ).to!uint;
	
	uint pageCount = (col_str)/limit; //Количество страниц
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
		std.file.append( eventLogFileName, 
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
	
	alias FieldType ft;
	
   ///Начинаем оформлять таблицу с данными
   auto touristRecFormat = RecordFormat!(
	ft.IntKey, "Ключ",   ft.Str, "Имя", ft.Str, "Дата рожд", 
	ft.Str,  "Опыт",   ft.Str, "Контакты",  ft.Str, "Комментарий")();
	
	string queryStr;
	
    
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
		   ` comment from tourist `~ ( ( fem.length == 0 )?"": (` WHERE family_name='` ~ fem ~"'") ) ~` order by num LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `;   
		   
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	string table = `<table border="1">`;
	table ~= `<tr>`;
	table ~= `<td> Ключ</td><td>Имя</td><td> Дата рожд</td><td> Опыт</td><td> Контакты</td><td> Комментарий</td>`; 
	foreach(rec; rs)
	{	table ~= `<tr>`;
		table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Имя"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Дата рожд"("") ~ `</td>`;
		table ~= `<td>` ~rec.get!"Опыт"("нет")  ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Контакты"("нет") ~ `</td>`;
		
		table ~= `<td>` ~ rec.get!"Комментарий"("нет") ~ `</td>`;
		
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
	tpl.set("img folder", "../../img/");
	tpl.set("css folder", "../../css/");
	tpl.set("cgi-bin", "/cgi-bin/mkk_site/");
	tpl.set("useful links", "Куча хороших ссылок");
	tpl.set("js folder", "../../js/");
	tpl.set("this page path", thisPagePath);
	
	import mkk_site.authentication;
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );
	
	if( !auth.isIdentified() || ( auth.userInfo.group != "admin" ) )
	{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
	}
	else 
	{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ auth.userInfo.name ~ "</b>!!!</i>");
	}
	
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

