module mkk_site.pohod;

import std.conv, std.string, std.utf, std.stdio, std.typecons;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context,webtank.net.utils;

import mkk_site;


//Функция отсечки SQL иньекций.отсечь все символы кромье букв и -

//----------------------
immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "pohod";
	PageRouter.join!(netMain)(thisPagePath);
}

string participantsList( size_t pohodNum ) //функция получения списка участников
{
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null;
	
	auto рез_запроса = dbase.query(
`with tourist_nums as (
	select unnest(unit_neim) as num from pohod where pohod.num = ` ~ pohodNum.to!string ~ `
)
select coalesce(family_name, '') || coalesce( ' ' || given_name, '' )
	||coalesce(' '||patronymic, '')||coalesce(', '||birth_year::text,'') from tourist_nums 
left join tourist
	on tourist.num = tourist_nums.num
`);
	

	
	string result;//список туристов
	
	if( рез_запроса.recordCount<1) 
		result ~= `Сведения об участниках <br> отсутствуют`;
	else
	{
		for( size_t i = 0; i < рез_запроса.recordCount; i++ )
		{	result ~=HTMLEscapeText(рез_запроса.get(0, i, "")) ~ `<br>`;	}
	}        
	           
	return result;
}

string linkList( size_t pohodNum ) //функция получения списка ссылок
{
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null;
	 auto рез_запроса= dbase.query(`select unnest(links) as num from pohod where pohod.num = ` ~ pohodNum.to!string ~ ` `); 
	  
   string result;//список ссылок	
	
	if( рез_запроса.recordCount < 1 ) 
		result ~= `отсутствуют`;
	else
	{  //result ~=`Cписок ссылок	 `;
		for( size_t i = 0; i < рез_запроса.recordCount; i++ )
		{	string[] linkPair = parseExtraFileLink( рез_запроса.get(0, i, "") );
			string link = HTMLEscapeText(linkPair[0]);
			string linkComment = ( linkPair[1].length ? HTMLEscapeText(linkPair[1]) : link );
			result ~=`<p><a href="` ~ link ~ `">` ~ linkComment ~ `</a></p>`;
			
		}
	}        
	           
	return result;
	
	 
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	//auto pVars = rq.postVars;
	auto qVars = rq.queryForm;
	string content ;//  содержимое страницы 	

	auto dbase = getCommonDB();
	
	size_t pohodKey;
	try {
		pohodKey = qVars.get("key", "0").to!size_t;
	}
	catch(std.conv.ConvException e)
	{	pohodKey = 0; }


	string queryStr = // основное тело запроса
`
select 
	pohod.num,
	kod_mkk,
	nomer_knigi,
	( coalesce(organization,'') || ' ' || coalesce(region_group,'') ) as organiz, 
	(
		date_part('day', begin_date) || '.' ||
		date_part('month', begin_date) || '.' ||
		date_part('YEAR', begin_date) 
		||' по '||
		date_part('day', finish_date) || '.' ||
		date_part('month', finish_date) || '.' ||
		date_part('YEAR', finish_date)
	) as dat,  
	vid,
	ks,
	elem,
	region_pohod, 
	marchrut,
	pohod.unit,
	case 
		when 
			chef.family_name is null
			and chef.given_name is null
			and chef.patronymic is null
		then
			'нет данных'
		else
			coalesce(chef.family_name, '')
			|| coalesce(' ' || chef.given_name,'')
			|| coalesce(' ' || chef.patronymic,'')
			|| coalesce(' ' || chef.birth_year::text,'')
	end as chef_name,  
	case 
		when 
			a_chef.family_name is null
			and a_chef.given_name is null
			and a_chef.patronymic is null
		then
			'нет'
		else
			coalesce(a_chef.family_name, '')
			|| coalesce(' ' || a_chef.given_name,'')
			|| coalesce(' ' || a_chef.patronymic,'')
			|| coalesce(' ' || a_chef.birth_year::text,'')
	end as a_chef_name,
	alt_chef,
	prepar,
	stat,
	chef_coment,
	"MKK_coment"
from pohod 
left outer join tourist chef 
	on pohod.chef_grupp = chef.num
left outer join tourist a_chef 
	on pohod.alt_chef = a_chef.num
`;     
      
	queryStr ~= ` where pohod.num = ` ~ pohodKey.to!string ~ ` ` ;

		
	auto pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Код МКК",
		string, "Номер книги",
		string, "Организация",
		string, "Сроки", 
		typeof(видТуризма), "Вид", 
		typeof(категорияСложности), "Категория", 
		typeof(элементыКС), "Элементы КС",
		string, "Район",
		string, "Маршрут",
		size_t, "Число участников",
		string, "ФИО руководителя",
		string, "ФИО зам. руководителя",
		size_t, "Номер зам. руководителя",
		typeof(готовностьПохода), "Готовность",
		typeof(статусЗаявки), "Статус",
		string, "Комментарий руководителя",
		string, "Комментарий МКК",
	)(
		null,
		tuple(
			видТуризма,
			категорияСложности,
			элементыКС,
			готовностьПохода,
			статусЗаявки
		)
	);
	
	auto rs = dbase.query(queryStr).getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	auto rec = rs.front;

	content ~= 
`	<p>Код МКК: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"Код МКК" ) ~`</span></p>
	<p>Маршрутная книжка: <span class="b-pohod e-value">№ ` ~ HTMLEscapeText( rec.getStr!"Номер книги" ) ~ `</span></p>
	<p>Группа туристов: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"Организация" ) ~ `</span></p>
	<p>Сроки похода: <span class="b-pohod e-value"> с ` ~ rec.getStr!"Сроки"  ~ `</span></p>
	<p>Вид туризма: <span class="b-pohod e-value">` ~ rec.getStr!"Вид" ~ `</span></p>
	<p>Категория сложности: <span class="b-pohod e-value">` ~ rec.getStr!"Категория";
	
	if( !rec.isNull("Элементы КС") && !rec.isNull("Категория") && rec.get!"Элементы КС" > rec.get!"Категория"  )
		content ~= ` ` ~ rec.getStr!"Элементы КС"();
	
	content ~= `</span></p>`;
	
	content ~= 
`	<p>Регион похода: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"Район" ) ~ `</span></p>
	<br>
	<p>По маршруту: <br><span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"Маршрут" ) ~ `</span></p>
	<br>
	<p>В составе: <span class="b-pohod e-value">` ~ rec.getStr!"Число участников" ~`</b></font> человек</p>
	<br>
	<p>Руководитель группы: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"ФИО руководителя" ) ~ `</span></p>
	<p>Зам. руководителя группы: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"ФИО зам. руководителя" ) ~`</span></p>
	<br>
	<p>Состав группы:</p>
	<p style="color: #556B2F; font-weight: bold;">` ~ participantsList( pohodKey ) ~ `</p>
	<br>
	<p>Готовность похода: <span class="b-pohod e-value">` ~ rec.getStr!"Готовность"("не известна") ~ `</span></p>
	<p>Статус заявки: <span class="b-pohod e-value">` ~ rec.getStr!"Статус"("не известен") ~ `</span></p>
	<br>
	<p>Коментарий руководителя: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"Комментарий руководителя"("нет") ) ~ `</span></p>
	<p>Коментарий MKK: <span class="b-pohod e-value">` ~ HTMLEscapeText( rec.getStr!"Комментарий МКК"("нет") ) ~ `</span></p>
	<br>
	<style>
		.b-pohod.e-value {
			color: #006400;
			font-weight: bold;
		}
	</style>
	<p>Дополнительные материалы:</p>` 
	~ linkList( pohodKey );

	return content;
}

