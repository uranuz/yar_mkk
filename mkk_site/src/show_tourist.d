module mkk_site.show_tourist;

import std.conv, std.string, std.utf;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site;

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
immutable thisPagePath = dynamicPath ~ "show_tourist";

shared static this()
{	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;

	bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	
	string output; //"Выхлоп" программы
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
		
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
	 
	 string raz_sud_kat;
	 
	// string [int] спортивныйРазряд=[0:"",3:"третий",2:"второй",1:"первый",
	// 30:"КМС",20:"МС",10:"ЗМС",5:"МСМК"];
	 
	 //string [int] судейскаяКатегория=[0:"",2:"вторая",1:"первая",10:"всероссийская",
	// 20:"всесоюзная",30:"международная"];
	 
	 
	string fem = nou_SQL_injekt( ( ( "family_name" in rq.bodyForm ) ? rq.bodyForm["family_name"] : "" ) ); // пропускаем фамилию через функцию отсечки

	try { //Логирование запросов к БД для отладки
	std.file.append( eventLogFileName, 
		"--------------------\r\n"
		"Фамилия: " ~ fem ~ "\r\n"
	);
	} catch(Exception) {}
	uint limit = 10;// максимальное  чмсло строк на странице
	// int page;
	auto col_str_qres = // запрос на число строк
	( fem.length == 0 ) ? dbase.query(`select count(1) from tourist` )://без фильтра
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
		
		content ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~ `" size="3"  maxlength="3" > из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `~ "\r\n";
		
		if( curPageNum != pageCount )
			content ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `~ "\r\n";
	}
	
	content ~= 
`	</form>
	<script type="text/javascript" src="` ~ js_file ~ `"></script>`~ "\r\n";
	
	alias FieldType ft;

   ///Начинаем оформлять таблицу с данными
   auto touristRecFormat = RecordFormat!(
	ft.IntKey, "Ключ",   ft.Str, "Имя", ft.Str, "Дата рожд", 
	ft.Str,  "Опыт",   ft.Str, "Контакты",
	ft.Int,  "Разряд",   ft.Int, "Категория",
	ft.Str, "Комментарий")();
	
	string queryStr;
	
    
		queryStr=//основной запрос
		`select num, 
		(family_name||'<br>'||coalesce(given_name,'')||'<br>'||coalesce(patronymic,'')) as name, `
		`( coalesce(birth_date,'')||'<br>'||birth_year ) as birth_date ,`
		`coalesce(exp,'???'), `
		`( case `
			` when( show_phone = true ) then phone||'<br> ' `
			` else '' `
		` end || `
		` case `
			` when( show_email = true ) then email `
			` else '' `
		   ` end ) as contact,razr,sud, `
		   ` comment from tourist `~ ( ( fem.length == 0 )?"": (` WHERE family_name ILIKE '%` ~ fem ~"%'") ) ~` order by num LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `; 
		   
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	string table = `<div style="max-width: 98%;"><table class="tab1">`~ "\r\n";
	table ~= `<tr>`~ "\r\n";
	if(_sverka) table ~= `<td> Кл.</td>`~ "\r\n";
	
	table ~=`<td width="20%" >Имя</td><td> Дата рожд</td><td> Опыт</td>
	<td> Разр.<br>Суд.кат.</td><td> Комментарий</td>`~ "\r\n";

	if(_sverka) table ~=`<td>"Изм."</td>`~ "\r\n"; 
	try {
	foreach(rec; rs)
	{	
		raz_sud_kat= спортивныйРазряд [rec.get!"Разряд"(1000)] ~ `<br>` ~ судейскаяКатегория [rec.get!"Категория"(1000)] ~ "\r\n";
		
		table ~= `<tr>`;
		if(_sverka) table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`~ "\r\n";
		table ~= `<td width="20%" >` ~ rec.get!"Имя"("") ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ rec.get!"Дата рожд"("") ~ `</td>`~ "\r\n";
		table ~= `<td>`
		~`<a href="`~dynamicPath~`show_pohod_for_tourist?key=`~rec.get!"Ключ"(0).to!string ~`">`
		~rec.get!"Опыт"("")  ~ ` </a>  </td>`~ "\r\n";
		
		table ~= `<td>` ~ raz_sud_kat ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ rec.get!"Комментарий"("нет") ~ `</td>`~ "\r\n";
		if(_sverka) table ~= `<td> <a href="`~dynamicPath~`edit_tourist?key=`~rec.get!"Ключ"(0).to!string~`">Изм.</a>  </td>`~ "\r\n";
		
		table ~= `</tr>`~ "\r\n";
	}
	} catch(Throwable exc)
	{}
	
	table ~= `</table></div>`~ "\r\n";

	if(_sverka) content ~= `<a href="edit_tourist" >Добавить нового туриста</a>`~ "\r\n";
	
	content ~= table; //Тобавляем таблицу с данными к содержимому страницы
	
	auto tpl = getGeneralTemplate(context);
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне
	
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

