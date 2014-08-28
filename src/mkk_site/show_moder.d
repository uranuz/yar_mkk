module mkk_site.show_moder;

import std.conv, std.string, std.utf;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context;

import mkk_site;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_moder";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;

	string content;

	auto authDB = getAuthDB(); //Объект подключения к БД аутентификации
	
	///Начинаем оформлять таблицу с данными
	static immutable touristRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ",
		string, "ФИО", 
		string, "Статус", 
		string, "Контакты"
	)();
	
	string queryStr = 
`select 
	num, name, 
	( coalesce(status,'') || coalesce(', ' || region, '') ) as stat,
	( coalesce(email,'') || coalesce('<br>' || contact_info, '') ) as contact 
from site_user order by num 
;`; 
	
	auto rs = authDB.query(queryStr).getRecordSet(touristRecFormat);
	
	string table = `<div><table class="tab1">`;
		
	table ~=`<tr><th>Имя</th><th>Статус</th><th> Контакты</th></tr>`;
	foreach(rec; rs)
	{	table ~= `<tr>`;
		
		table ~= `<td>` ~ rec.get!"ФИО"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Статус"("") ~ `</td>`;
	      //table ~= `<td>` ~rec.get!"Опыт"("нет")  ~ `</td>`;
		table ~= `<td>` ~ rec.get!"Контакты"("нет") ~ `</td>`;		
	      //table ~= `<td>` ~ rec.get!"Комментарий"("нет") ~ `</td>`;
				
		table ~= `</tr>`;
	}
	table ~= `</table></div>`;

	content ~= table; //Тобавляем таблицу с данными к содержимому страницы
	
	return content;
}


