module mkk_site.show_moder;

import std.conv, std.string, std.utf;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site;


//----------------------
immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_moder";
	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;

	string output; //"Выхлоп" программы
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
		
	//Создаём подключение к БД
	auto dbase = new DBPostgreSQL(authDBConnStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
	
	//rq.bodyFormArray[] формирует ассоциативный массив массивов из строки возвращаемой по пост запросу
	   
	string fem = ( ( "name" in rq.bodyForm ) ? rq.bodyForm["name"] : "" ) ;
	
	/*try { //Логирование запросов к БД для отладки
	std.file.append( eventLogFileName, 
		"--------------------\r\n"
		"Фамилия: " ~ fem ~ "\r\n"
	);
	} catch(Exception) {}*/
	//uint limit = 10;// максимальное  чмсло строк на странице
	//int page;
	//auto col_str_qres = ( fem.length == 0 ) ? dbase.query(`select count(1) from tourist` ):
	//dbase.query(`select count(1) from tourist where family_name = '` ~ fem ~ "'");

	//if( col_str_qres.recordCount > 0 ) //Проверяем, что есть записи
	//Количество строк в таблице
	//uint col_str = ( col_str_qres.get(0, 0, "0") ).to!uint;
	
	//uint pageCount = (col_str)/limit; //Количество страниц
	//uint curPageNum = 1; //Номер текущей страницы
	//try {
	//	if( "cur_page_num" in rq.bodyForm )
 	//		curPageNum = rq.bodyForm.get("cur_page_num", "1").to!uint;
	//} catch (Exception) { curPageNum = 1; }

	//uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	string content = ``;
	
	/*try { //Логирование запросов к БД для отладки
		std.file.append( eventLogFileName, 
			"--------------------\r\n"
			"Количество записей: " ~ col_str.to!string ~ "\r\n"
			//"Текущий номер страницы: "~ curPageNum.to!string ~ ", всего страниц: " ~ pageCount.to!string ~ "\r\n"
		);
	} catch(Exception) {}*/


	content ~= `<script type="text/javascript" src="` ~ js_file ~ `"></script>`;

   ///Начинаем оформлять таблицу с данными
   auto touristRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ",
		string, "ФИО", 
		string, "Статус", 
		string, "Контакты"
	)();
	
	string queryStr;
	
   
		queryStr=`select num,name,(coalesce(status,'')||'<br>'||coalesce(region,'')) as stat,(coalesce(email,'')||'<br>'||coalesce(contact_info,'')) as contact from site_user order by num `;   
		   
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	
	
	
	string table = `<div   ><table class="tab1">`;
	table ~= `<tr>`;
		
	table ~=`<td>ФИО</td><td> Статус</td><td> Контакты</td>`;
	
	foreach(rec; rs)
	{	table ~= `<tr>`;
		
		table ~= `<td>` ~ rec.get!"ФИО"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Статус"("") ~ `</td>`;
	      //table ~= `<td>` ~rec.get!"Опыт"("нет")  ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Контакты"("нет") ~ `</td>`;		
	      //table ~= `<td>` ~ rec.get!"Комментарий"("нет") ~ `</td>`;
				
		table ~= `</tr>`;
	}
	table ~= `</table>   </div>`;

	
	
	content ~= table; //Тобавляем таблицу с данными к содержимому страницы
	
	auto tpl = getGeneralTemplate(context);
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне
	
	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

