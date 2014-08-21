module mkk_site.show_pohod;

import std.conv, std.string , std.array;
import std.exception : ifThrown;
import std.file; //Стандартная библиотека по работе с файлами
//import webtank.db.database;
import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.templating.plain_templater, webtank.net.http.context;

import webtank.common.optional;
import webtank.common.conv;

import mkk_site;

static immutable string thisPagePath;

shared static this()
{	thisPagePath = dynamicPath ~ "show_pohod";
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(participantsList);
}


string participantsList( size_t pohodNum )
{
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null;
	
	auto рез_запроса = dbase.query(`with tourist_nums as (
select unnest(unit_neim) as num from pohod where pohod.num = ` ~ pohodNum.to!string ~ `
)
select coalesce(family_name, '')||coalesce(' '||given_name,'')
||coalesce(' '||patronymic, '')||coalesce(', '||birth_year::text,'') from tourist_nums 
left join tourist
on tourist.num = tourist_nums.num
	`);
	
	auto поход = dbase.query( `select (coalesce(kod_mkk , '')
	||' Маршрутка № '||coalesce( nomer_knigi, 'нет сведений') 
	||'.<br> Район проведения '||coalesce(region_pohod, '')) as poh from pohod where pohod.num = ` ~ pohodNum.to!string ~ ` `);
	
	string result;//список туристов
	result ~= поход.get(0, 0, null) ~ `<hr>`;
	
	
	if( рез_запроса.recordCount < 1 ) result ~= `Сведения об участниках <br> отсутствуют`;
	else
	{
		for( size_t i = 0; i < рез_запроса.recordCount; i++ )
		{	result ~= рез_запроса.get(0, i, "") ~ ` <br>`; }
	}
	           
	return result;
	
	
}


struct ФильтрПоходов
{
	Optional!int вид;
	int[] категории;
	OptionalDate[string] сроки;
	
	bool естьФильтрация() @property
	{
		if( !вид.isNull || категории.length > 0 )
			return true;
			
		foreach( дата; this.сроки )
		{
			if( !дата.isNull )
				return true;
		}
		
		return false;
	}
}



struct СоотвПолейСроков { 
		string имяВФорме; 
		string имяВБазе; 
		string опСравн;
};
	
//Вспомогательный массив структур для составления запроса
//Устанавливает соответствие между полями в форме и в базе
//и операциями сравнения, которые будут в запросе
static immutable СоотвПолейСроков[] соотвПолейСроков = [
	{ "begin_date_range_head", "begin_date", "<=" },
	{ "begin_date_range_tail", "begin_date", ">=" },
	{ "end_date_range_head", "finish_date", "<=" },
	{ "end_date_range_tail", "finish_date", ">=" }
];

import webtank.view_logic.html_controls;

string отрисоватьБлокФильтрации(ФильтрПоходов фильтрПоходов)
{
	string разметка;
	
	auto списокВидовТуризма = listBox(видТуризма);
	списокВидовТуризма.nullName = "любой";
	списокВидовТуризма.name = "vid";
	списокВидовТуризма.selectedValue = фильтрПоходов.вид;
	
	auto списокКатегорий = listBox(категорияСложности);
	списокКатегорий.nullName = "любая";
	списокКатегорий.name = "ks";
	списокКатегорий.selectedValues = фильтрПоходов.категории;
	
	PlainDatePicker[string] поляДат;
	foreach( имяПоля, дата; фильтрПоходов.сроки )
	{
		auto полеДаты = new PlainDatePicker;
		полеДаты.name = имяПоля;
		полеДаты.date = дата;
		полеДаты.nullDayName = "день";
		полеДаты.nullMonthName = "месяц";
		полеДаты.nullYearName = "год";
		
		поляДат[имяПоля] = полеДаты;
	}
	разметка ~= `Вид туризма: ` ~ списокВидовТуризма.print() ~ "<br>\r\n"
		~ `Категория сложности: ` ~ списокКатегорий.print() ~ "<br>\r\n"
		~ "Диапазон сроков начала похода: <br>\r\n"
		~ "c " ~ поляДат["begin_date_range_head"].print() 
		~ " по " ~ поляДат["begin_date_range_tail"].print() ~ "<br>\r\n"
		~ "Диапазон сроков окончания похода: <br>\r\n"
		~ "c " ~ поляДат["end_date_range_head"].print() 
		~ " по " ~ поляДат["end_date_range_tail"].print() ~ "<br>\r\n";
	
	разметка ~= `<input type="submit" value="Найти">` ~ "<br>\r\n";
	
	return разметка;
}


ФильтрПоходов получитьФильтрПоходов(HTTPContext context)
{
	auto rq = context.request;
	
	//Получаем параметры фильтрации из запроса
	ФильтрПоходов фильтрПоходов;
	
	фильтрПоходов.вид = rq.bodyForm.get("vid", null).conv!(Optional!(int))
		.ifThrown!ConvException(Optional!int(null));
		
	фильтрПоходов.категории = rq.bodyForm.array("ks").conv!(int[]).ifThrown!ConvException(null);
	
	foreach( соотвПоля; соотвПолейСроков )
	{
		фильтрПоходов.сроки[соотвПоля.имяВФорме] = OptionalDate(
			rq.bodyForm.get( соотвПоля.имяВФорме ~ "__year", null ).conv!(Optional!short),
			rq.bodyForm.get( соотвПоля.имяВФорме ~ "__month", null ).conv!(Optional!ubyte),
			rq.bodyForm.get( соотвПоля.имяВФорме ~ "__day", null ).conv!(Optional!ubyte)
		);
	}
	
	return фильтрПоходов;
}


//Формирует чать запроса по фильтрации походов (для SQL-секции where)
string получитьЧастьЗапроса_фильтрПоходов(const ref ФильтрПоходов фильтрПоходов)
{
	import std.datetime: Date;
	
	string[] частиЗапроса_фильтрыПоходов;
	
	if( !фильтрПоходов.вид.isNull )
		частиЗапроса_фильтрыПоходов ~= `vid = ` ~ фильтрПоходов.вид.conv!string; // добавлние запроса по виду туризма
	
	if( фильтрПоходов.категории !is null )
		частиЗапроса_фильтрыПоходов ~= `ks in(` ~ фильтрПоходов.категории.conv!(string[]).join(", ") ~ `)`;
	
	string[] частиЗапроса_фильтрыСроковПохода;
	
	static immutable назвЧастейДаты = [ "year", "month", "day" ];
	
	foreach( соотвПоля; соотвПолейСроков )
	{
		OptionalDate фильтрДаты = фильтрПоходов.сроки[ соотвПоля.имяВФорме ];
		
		if( !фильтрДаты.year.isNull && !фильтрДаты.month.isNull && !фильтрДаты.day.isNull )
		{
			частиЗапроса_фильтрыСроковПохода ~= ` ('` ~ Date( фильтрДаты.tupleof ).conv!string ~ `'::date ` 
				~ соотвПоля.опСравн ~ ` ` ~ соотвПоля.имяВБазе ~ `) `;
		}
		else
		{
			foreach( j, частьДаты; фильтрДаты.tupleof )
			{
				if( !частьДаты.isNull )
				{
					частиЗапроса_фильтрыСроковПохода ~= ` ( ` ~ частьДаты.conv!string ~ ` `
						~ соотвПоля.опСравн ~ ` date_part('` ~ назвЧастейДаты[j] ~ `', ` ~ соотвПоля.имяВБазе ~ `) ) `;
				}
			}
		}
	}
	
	частиЗапроса_фильтрыПоходов ~= частиЗапроса_фильтрыСроковПохода;
	
	return ( частиЗапроса_фильтрыПоходов.length > 0 ?
		" ( " ~ частиЗапроса_фильтрыПоходов.join(" ) and ( ") ~ " ) " : null );
}




void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	string output; //"Выхлоп" программы 
	scope(exit) rp.write(output);
	
	//Создаём подключение к БД
	auto dbase = getCommonDB();
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
		
	//string параметрыПоиска;//контроль изменения парамнтров фильтрации
	//string параметрыПоиска_старое = rq.bodyForm.get("параметрыПоиска", "");
	
// 	bool естьФильтрация;    // котроль необходимости фильтрации
	bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	
	ФильтрПоходов фильтрПоходов = получитьФильтрПоходов(context);
	
	string строкаЗапроса_фильтрыПохода = получитьЧастьЗапроса_фильтрПоходов(фильтрПоходов);
	
	string запросКоличестваПоходов = `select count(1) from pohod`;
 	
	if( фильтрПоходов.естьФильтрация )
		запросКоличестваПоходов ~= ` where ` ~ строкаЗапроса_фильтрыПохода;
	
	uint limit = 10;// максимальное  число строк на странице
	uint количествоПоходов = dbase.query(запросКоличестваПоходов).get(0, 0, "0").to!uint;
	
	uint pageCount = количествоПоходов/limit+1; //Количество страниц
	uint curPageNum = rq.bodyForm.get("cur_page_num", "1").to!(uint).ifThrown!ConvException(1); //Номер текущей страницы
	
	if( curPageNum > pageCount ) curPageNum = pageCount; 
	//если номер страницы больше числа страниц переходим на последнюю 
	//?? может лучше на первую

	//if( параметрыПоиска_старое != параметрыПоиска ) curPageNum = 1;
	//если параметры поиска изменились переходим на 1-ю страницу
	
	uint offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	
	import std.typecons;
	
	auto pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Номер книги", 
		string, "Сроки", 
		typeof(видТуризма), "Вид", 
		typeof(категорияСложности), "кс", 
		typeof(элементыКС), "элем",
		string,"Район",
		string,"Руководитель", 
		string, "Число участников",
		string,"Организация",
		string, "Нитка маршрута",
		typeof(готовностьПохода), "Готовность",
		typeof(статусЗаявки), "Статус"
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
	//WHERE
	
	string запросСпискаПоходов = // основное тело запроса
`
with 
t_chef as (
	select 
		pohod.num, /*номер похода*/
		(
			coalesce(T.family_name,'нет данных')||'<br> '
			||coalesce(T.given_name,'')||'<br> '
			||coalesce(T.patronymic,'')||'<br>'
			||coalesce(T.birth_year::text,'')
		) as fio  
		/* создаётся таблица номера руководителей похода - их ФИО г.р.*/

	from pohod
	LEFT join tourist T
		on pohod.chef_grupp = T.num
)

select 
	pohod.num,
	( coalesce(kod_mkk,'000-00') || '<br>' || coalesce(nomer_knigi, '00-00') ) as nomer_knigi,   
	(
		date_part('day', begin_date) || '.' ||
		date_part('month', begin_date) || '.' ||
		date_part('YEAR', begin_date) 
		||' <br> '||
		date_part('day', finish_date) || '.' ||
		date_part('month', finish_date) || '.' ||
		date_part('YEAR', finish_date)
	) as dat,  
	vid,
	ks,
	elem,
	region_pohod, 
	t_chef.fio, 
	( coalesce(pohod.unit, '') ) as kol_tur,
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as organiz, 
	( coalesce(marchrut::text, '') || '<br>' || coalesce(chef_coment::text, '') ) as marchrut, 
	prepar,
	stat 
from pohod 
LEFT OUTER JOIN t_chef
	on t_chef.num = pohod.num
`;     
      
	if( фильтрПоходов.естьФильтрация )
		запросСпискаПоходов ~= ` where ` ~ строкаЗапроса_фильтрыПохода; // добавляем фильтрации
		
	запросСпискаПоходов ~= ` order by pohod.begin_date DESC LIMIT ` ~ limit.to!string ~ ` OFFSET ` ~ offset.to!string ~ ` `;
	
	auto rs = dbase.query(запросСпискаПоходов).getRecordSet(pohodRecFormat);

	// окна выбора страницы
	string pageSelector = `<table><tr><td style='width: 100px;'>`
	~ ( (curPageNum > 1) ? `<a href="#" onClick="gotoPage(` ~ (curPageNum - 1).to!string ~ `)">Предыдущая</a>` : "" )
	
	~ "</td><td>"~ "\r\n"
	~ ` Страница <input name="cur_page_num" type="text" size="4" maxlength="4" value="` ~ curPageNum.to!string ~ `"> из ` 
	~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `
	~ "</td><td>" ~ "\r\n"
	~ ( (curPageNum < pageCount ) ? `<a href="#" onClick="gotoPage(` ~ (curPageNum + 1).to!string ~ `)">Следующая</a>` : "")
	~ "</td></tr></table>" ~ "\r\n";    
	    
	// Начало формирования основной отображающей таблицы  
	string table = `<table class="tab1" >`;
	
	if(_sverka) table ~= `<td>Кл.</td>`~ "\r\n";// появляется при наличии допуска
	
	table ~= `<td>Номер</td><td>Сроки похода</td><td>Вид, категория</td><td>Район</td><td>Руководитель</td><td>Участники</td><td>Город, организация</td><td>Статус похода</td>` ~ "\r\n";
	if(_sverka) table ~=`<td>Изм.</td>`~ "\r\n";// появляется при наличии допуска
	foreach(rec; rs)
	{
	   string vke = rec.getStr!"Вид"() ~ `<br>` ~ rec.getStr!"кс"() ~ ` ` ~ rec.getStr!"элем"("") ;
	   string ps  = ( rec.isNull("Готовность") ? "" : rec.getStr!"Готовность"("") ~ `<br>` ) ~ rec.getStr!"Статус"("");
	  
		table ~= `<tr>`;
	  
		if(_sverka) table ~= `<td>` ~ rec.get!"Ключ"(0).to!string ~ `</td>`~ "\r\n";// появляется при наличии допуска
		
		table ~= `<td> <a href="` ~ dynamicPath ~ `pohod?key=`
			~ rec.get!"Ключ"(0).to!string ~ `">`~rec.get!"Номер книги"("нет") ~`</a>  </td>`~ "\r\n";
	
		 
		table ~= `<td>` ~ rec.get!"Сроки"("нет")  ~ `</td>`~ "\r\n";
		table ~= `<td>` ~  vke ~ `</td>`~ "\r\n";
		table ~= `<td width="8%">` ~ rec.get!"Район"("нет") ~ `</td>`~ "\r\n";
		table ~= `<td>` ~ rec.get!"Руководитель"("нет")  ~ `</td>`~ "\r\n";
		
		table ~= `<td  class="show_participants_btn"  style="text-align: center;">`~ "\r\n" 
		~ (  rec.get!"Число участников"("Не задано") ) ~ `<img src="` ~ imgPath ~ `icons/list_icon.png">`
		~ `	<input type="hidden" value="`~rec.get!"Ключ"(0).to!string~`"> 
		</td>`~ "\r\n";
		
		
		table ~= `<td>` ~ rec.get!"Организация"("нет")  ~ `</td>`~ "\r\n";

		table ~= `<td>` ~ ps  ~ `</td>`~ "\r\n";
		
		if(_sverka)
			table ~= `<td> <a href="` ~ dynamicPath ~ `edit_pohod?key=`
			~ rec.get!"Ключ"(0).to!string ~ `">Изм.</a> </td>`~ "\r\n";// появляется при наличии допуска
			
		table ~= `</tr>` ~ "\r\n";
		table ~= `<tr>` ~ `<td style="background-color:#8dc0de;" colspan="`;
		if(_sverka)
			table ~= `10`;
		else
			table ~= `8`;
		
		table ~= `">Нитка маршрута: ` ~ rec.get!"Нитка маршрута"("нет") ~ `</td>` ~ `</tr>`~ "\r\n";
	}
	table ~= `</table>` ~ "\r\n";
	// конец формирования основной таблицы
	
	string content;
	
	content ~= `<link rel="stylesheet" type="text/css" href="` ~ cssPath ~ `page_styles.css">`;
	
	content ~= `<form id="main_form" method="post">`// содержимое страницы
	~ отрисоватьБлокФильтрации(фильтрПоходов) ~ pageSelector ~ `</form><br><br>`~ "\r\n"
	~ ( _sverka ? `<a href="` ~ dynamicPath ~ `edit_pohod">Добавить новый поход</a><br>` ~ "\r\n" : "" )
	~ `<p> Число походов ` ~ количествоПоходов.to!string ~ ` </p>`~ "\r\n"
	~ table; //Тобавляем таблицу с данными к содержимому страницы
	
	//Подключение JavaScript файла с именем, указанным в атрибуте src
	content ~= `<script src="` ~ jsPath ~ "show_pohod.js" ~ `"></script>`;
	
	//Создаем шаблон по файлу
	auto tpl = getGeneralTemplate(context);
	tpl.set( "content", content ); //Устанавливаем содержимое по метке в шаблоне

	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}
