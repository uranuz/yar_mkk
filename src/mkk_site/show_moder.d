module mkk_site.show_moder;

import std.conv, std.string, std.utf;//  strip()       Уибират начальные и конечные пробелы

import mkk_site.page_devkit;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_moder";
	PageRouter.join!(netMain)(thisPagePath);
}

class Moder
{
public:
	///Начинаем оформлять таблицу с данными
	static immutable moderRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ",
		string, "ФИО", 
		string, "Статус", 
		string, "Контакты",
		size_t, "Ключ туриста"
	)();
	
	static immutable moderListQuery = 
`select 
	num as "Ключ", 
	name as "ФИО", 
	( coalesce(status,'') || coalesce(', ' || region, '') ) as "Статус",
	( coalesce(email,'') || coalesce('<br>' || contact_info, '') ) as "Контакты",
	tourist_num as "Ключ туриста"
	
	from site_user
	where "user_group" in ('moder', 'admin')
	order by num
;`;
	
	static auto list()
	{
		return getAuthDB()
			.query(moderListQuery)
			.getRecordSet(moderRecFormat);
	}
}

class ModerView
{
public:
	static string render(RS)(RS rs)
	{
		import std.array: appender;
		
		auto table = appender!string();
		
		table ~= `<div><table class="tab1">`;
		
		table ~=`<tr><th>Имя</th><th>Статус</th><th>Контакты</th></tr>`;
		foreach(rec; rs)
		{	
			table ~= `<tr>`;
			
			table ~= `<td>`;
				if( rec.isNull("Ключ туриста") )
					table ~= rec.get!"ФИО"("");
				else //Делаем ссылку на туриста, если пользователь связан с туристом
					table ~= `<a href="` ~ dynamicPath ~ "show_pohod_for_tourist?key=" ~ rec.getStr!"Ключ туриста"() ~ `">` ~ rec.get!"ФИО"("") ~ `</a>`;
					
			table ~= `</td>`;
			
			table ~= `<td>` ~ rec.get!"Статус"("") ~ `</td>`
				~ `<td>` ~ rec.get!"Контакты"("нет") ~ `</td>`;
			
			table ~= `</tr>`;
		}
		table ~= `</table></div>`;

		return table.data();
	}

}

string netMain(HTTPContext context)
{	
	auto rs = Moder.list();

	return ModerView.render(rs);
}


