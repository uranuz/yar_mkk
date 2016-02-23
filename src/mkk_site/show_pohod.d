module mkk_site.show_pohod;

import std.conv, std.string , std.array;
import std.exception : ifThrown;
import std.file; //Стандартная библиотека по работе с файлами
//import webtank.db.database;
import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.templating.plain_templater, webtank.net.http.context;

import webtank.common.optional;
import webtank.common.conv;

import mkk_site,std.stdio;
//--дипазон дата
/*печатьДиапазонаДат()
{
OptionalDate фильтрДаты фильтрДаты = фильтрПоходов.сроки[ соотвПоля.имяВФорме ];
		
		if( фильтрДаты.isDefined )
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
					частиЗапроса_фильтрыСроковПохода ~= частьДаты.conv!string ~ ` `
						~ соотвПоля.опСравн ~ ` date_part('` ~ назвЧастейДаты[j] ~ `', ` ~ соотвПоля.имяВБазе ~ `)`;
				}
			}
		}
	return	
}
//-----------------------*/
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
	int[] видыТуризма;
	int[] категории;
	int[] готовности;
	int[] статусыЗаявки;
	OptionalDate[string] сроки;
	string районПохода;
	bool сМатериалами;	
		
	bool естьФильтрация() @property
	{
		if( видыТуризма.length > 0 || категории.length > 0 || 
			готовности.length > 0 || статусыЗаявки.length > 0 ||
			районПохода.length > 0 || сМатериалами
		) return true;
			
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

import webtank.view_logic.html_controls, webtank.net.utils;

/////////////////////////////////////

string отрисоватьБлокФильтрации(ФильтрПоходов фильтрПоходов)
{
	auto списокВидовТуризма = checkBoxList(видТуризма);
	списокВидовТуризма.nullName = "любой";
	списокВидовТуризма.name = "vid";
	списокВидовТуризма.classes ~= [`b-pohod_filter_vid`, `e-block`];
	списокВидовТуризма.selectedValues = фильтрПоходов.видыТуризма;
	
	auto списокКатегорий = checkBoxList(категорияСложности);
	списокКатегорий.nullName = "любая";
	списокКатегорий.name = "ks";
	списокКатегорий.classes ~= [`b-pohod_filter_ks`, `e-block`];
	списокКатегорий.selectedValues = фильтрПоходов.категории;
	
	auto списокГотовностей = checkBoxList(готовностьПохода);
	списокГотовностей.nullName = "любая";
	списокГотовностей.name = "prepar";
	списокГотовностей.classes ~= [`b-pohod_filter_prepar`, `e-block`];
	списокГотовностей.selectedValues = фильтрПоходов.готовности;
	
	auto списокСтатусовЗаявки = checkBoxList(статусЗаявки);
	списокСтатусовЗаявки.nullName = "любая";
	списокСтатусовЗаявки.name = "stat";
	списокСтатусовЗаявки.classes ~= [`b-pohod_filter_stat`, `e-block`];
	списокСтатусовЗаявки.selectedValues = фильтрПоходов.статусыЗаявки;
	
	import std.file : read;
	import std.path : buildPath;
	
	string текстШаблонаФормыФильтрации = cast(string) std.file.read( buildPath(pageTemplatesDir, "pohod_filter_form.html" ) );
	auto формаФильтрации = new PlainTemplater( текстШаблонаФормыФильтрации );
	
	foreach( имяПоля, дата; фильтрПоходов.сроки )
	{
		auto полеДаты = new PlainDatePicker;
		полеДаты.name = имяПоля;
		полеДаты.date = дата;
		полеДаты.nullDayName = "день";
		полеДаты.nullMonthName = "месяц";
		полеДаты.nullYearName = "год";
		
		формаФильтрации.set( имяПоля, полеДаты.print() );
	}
	
	with( формаФильтрации )
	{
		set( "vid", списокВидовТуризма.print() );
		set( "ks", списокКатегорий.print() );
		set( "prepar", списокГотовностей.print() );
		set( "stat", списокСтатусовЗаявки.print() );
		
		set( "region_pohod", HTMLEscapeValue(фильтрПоходов.районПохода) );
		if( фильтрПоходов.сМатериалами )
			set( "with_files", ` checked="checked"` );
	}

	return формаФильтрации.getString();
}
	/////////////////////	
	
string отрисоватьБлокФильтрации_для_печати(ФильтрПоходов фильтрПоходов)
{   import std.array: join;
//----------вид Туризма--------------------------------------
	string[] строкиВидов;
	if (фильтрПоходов.видыТуризма.length)
	{
		foreach( вид;	фильтрПоходов.видыТуризма )
		{	
			if( видТуризма.hasValue(вид) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиВидов ~= видТуризма.getName(вид);
			}
		}
	}
	else
	{
		строкиВидов ~= "Все виды";
	}	
	
	string списокВидовТуризма = строкиВидов.join(",<br>");
	//-------категория Сложности---------------------------------------------
	string[] строкиКС;
	if (фильтрПоходов.видыТуризма.length)
	{
		foreach( кс;	фильтрПоходов.видыТуризма )
		{	
			if( готовностьПохода.hasValue(кс) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиКС ~= готовностьПохода.getName(кс);
			}
		}
	}
	else
	{
		строкиКС ~= "Все категории";
	}	
	
	string списокКС = строкиКС.join(",<br>");
	
	//------готовность похода----------------------------------------------
	string[] строкиПодготовка;
	if (фильтрПоходов.видыТуризма.length)
	{
		foreach( гп;	фильтрПоходов.видыТуризма )
		{	
			if( статусЗаявки.hasValue(гп) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиПодготовка ~= статусЗаявки.getName(гп);
			}
		}
	}
	else
	{
		строкиПодготовка ~= "Все походы";
	}	
	
	string списокПодготовка = строкиПодготовка.join(",<br>");
	
	//---------статус Заявка-------------------------------------------
		string[] строкиЗаявка;
	if (фильтрПоходов.видыТуризма.length)
	{
		foreach( сз;	фильтрПоходов.видыТуризма )
		{	
			if( готовностьПохода.hasValue(сз) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиЗаявка ~= готовностьПохода.getName(сз);
			}
		}
	}
	else
	{
		строкиЗаявка ~= "Все походы";
	}	
	
	string списокЗаявка = строкиЗаявка.join(",<br>");
	
	//----------------------------------------------------
	

	
	import std.file : read;
	import std.path : buildPath;
	
	string текстШаблонаФормыФильтрации = cast(string) std.file.read( buildPath(pageTemplatesDir, "pohod_filter_print.html" ) );
	auto формаФильтрации = new PlainTemplater( текстШаблонаФормыФильтрации );
	
	foreach( имяПоля, дата; фильтрПоходов.сроки )
	{
		auto полеДаты = new PlainDatePicker;
		полеДаты.name = имяПоля;
		полеДаты.date = дата;
		полеДаты.nullDayName = "день";
		полеДаты.nullMonthName = "месяц";
		полеДаты.nullYearName = "год";
		
		формаФильтрации.set( имяПоля, полеДаты.print() );
	}
	
	with( формаФильтрации )
	{
		set( "vid", списокВидовТуризма );
		set( "ks" , списокКС);
		set( "prepar", списокПодготовка );
		set( "stat", списокЗаявка);
		
		set( "region_pohod", HTMLEscapeValue(фильтрПоходов.районПохода) );
		if( фильтрПоходов.сМатериалами )
			set( "with_files", ` checked="checked"` );
	}

	
	return формаФильтрации.getString();
}

	//////////////////////////////////////////////////////////////////////////////////////////////
ФильтрПоходов получитьФильтрПоходов(HTTPContext context)
{
	auto rq = context.request;
	
	//Получаем параметры фильтрации из запроса
	ФильтрПоходов фильтрПоходов;
	
	фильтрПоходов.видыТуризма = rq.bodyForm.array("vid").conv!(int[]).ifThrown!ConvException(null);
	фильтрПоходов.категории = rq.bodyForm.array("ks").conv!(int[]).ifThrown!ConvException(null);
	фильтрПоходов.готовности = rq.bodyForm.array("prepar").conv!(int[]).ifThrown!ConvException(null);
	фильтрПоходов.статусыЗаявки = rq.bodyForm.array("stat").conv!(int[]).ifThrown!ConvException(null);
	
	фильтрПоходов.сМатериалами = rq.bodyForm.get( "with_files", null ) == "on";

	foreach( соотвПоля; соотвПолейСроков )
	{
		фильтрПоходов.сроки[соотвПоля.имяВФорме] = OptionalDate(
			rq.bodyForm.get( соотвПоля.имяВФорме ~ "__year", null ).conv!(Optional!short),
			rq.bodyForm.get( соотвПоля.имяВФорме ~ "__month", null ).conv!(Optional!ubyte),
			rq.bodyForm.get( соотвПоля.имяВФорме ~ "__day", null ).conv!(Optional!ubyte)
		);
	}
	
	import std.string;
	
	фильтрПоходов.районПохода = PGEscapeStr( strip( rq.bodyForm.get( "region_pohod", null ) ) );
	
	return фильтрПоходов;
}


//Формирует чать запроса по фильтрации походов (для SQL-секции where)
string получитьЧастьЗапроса_фильтрПоходов(const ref ФильтрПоходов фильтрПоходов)
{
	import std.datetime: Date;
	
	string[] частиЗапроса_фильтрыПоходов;
	
	if( фильтрПоходов.видыТуризма.length > 0 )
		частиЗапроса_фильтрыПоходов ~= `vid in(` ~ фильтрПоходов.видыТуризма.conv!(string[]).join(", ") ~ `)`;
	
	if( фильтрПоходов.категории.length > 0 )
		частиЗапроса_фильтрыПоходов ~= `ks in(` ~ фильтрПоходов.категории.conv!(string[]).join(", ") ~ `)`;
		
	if( фильтрПоходов.готовности.length > 0 )
		частиЗапроса_фильтрыПоходов ~= `prepar in(` ~ фильтрПоходов.готовности.conv!(string[]).join(", ") ~ `)`;
		
	if( фильтрПоходов.статусыЗаявки.length > 0 )
		частиЗапроса_фильтрыПоходов ~= `stat in(` ~ фильтрПоходов.статусыЗаявки.conv!(string[]).join(", ") ~ `)`;
	
	if( фильтрПоходов.сМатериалами )
		частиЗапроса_фильтрыПоходов ~= `(array_length(links, 1) != 0 AND array_to_string(links, '', '')!= '')`;
	
	string[] частиЗапроса_фильтрыСроковПохода;
	
	static immutable назвЧастейДаты = [ "year", "month", "day" ];
	
	foreach( соотвПоля; соотвПолейСроков )
	{
		OptionalDate фильтрДаты = фильтрПоходов.сроки[ соотвПоля.имяВФорме ];
		
		if( фильтрДаты.isDefined )
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
					частиЗапроса_фильтрыСроковПохода ~= частьДаты.conv!string ~ ` `
						~ соотвПоля.опСравн ~ ` date_part('` ~ назвЧастейДаты[j] ~ `', ` ~ соотвПоля.имяВБазе ~ `)`;
				}
			}
		}
	}
	
	частиЗапроса_фильтрыПоходов ~= частиЗапроса_фильтрыСроковПохода;
	
	if( фильтрПоходов.районПохода.length > 0 )
		частиЗапроса_фильтрыПоходов ~= `region_pohod ILIKE '%` ~ фильтрПоходов.районПохода ~ `%'`;
	
	return ( частиЗапроса_фильтрыПоходов.length > 0 ?
		" ( " ~ частиЗапроса_фильтрыПоходов.join(" ) and ( ") ~ " ) " : null );
}
//-------------------------------------------------------------

// -------Формирует информационную строку о временном диапозоне поиска походов
string поисковый_диапозон_Походов(const ref ФильтрПоходов фильтрПоходов)
{
	import std.datetime: Date;		
	
		OptionalDate фильтрДатыНачало = фильтрПоходов.сроки[ "begin_date_range_head" ];
		OptionalDate фильтрДатыКонец = фильтрПоходов.сроки[ "end_date_range_tail" ];
		//writeln(фильтрДатыНачало);
		//writeln(фильтрДатыКонец);
		string [] _месяцы =["января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря"];
		string район;
		string beginDateStr;
		string endDateStr;
		
		if( фильтрПоходов.районПохода!="" ) район~="<br/>Район похода содержит [ "~фильтрПоходов.районПохода~" ].<br/>";
		if( фильтрПоходов.сМатериалами ) район~=" По данным походам имеются отчёты или дополнительные материалы.<br/><br/>";
		
		if(фильтрДатыНачало.isNull) beginDateStr~=" не определено";
		else
		{
		   if(  !фильтрДатыНачало.day.isNull ||  !фильтрДатыНачало.month.isNull)
		   {
		   beginDateStr ~= фильтрДатыНачало.day.isNull ? "" : фильтрДатыНачало.day.to!string ~ ` `;
		       if(фильтрДатыНачало.day.isNull)
		           beginDateStr ~= фильтрДатыНачало.month.isNull ? "число любого месяца" : месяцы.getName(фильтрДатыНачало.month);
		       else 		          
		          
		           beginDateStr ~= фильтрДатыНачало.month.isNull ? "число любого месяца" : месяцы_родительный.getName(фильтрДатыНачало.month);
		   }
		beginDateStr ~=` `~ (фильтрДатыНачало.year.isNull ? "" : фильтрДатыНачало.year.to!string);
		}
		
		if(фильтрДатыКонец.isNull) endDateStr~=" не определён ";
		else
		{ 
		   if(  !фильтрДатыКонец.day.isNull ||  !фильтрДатыКонец.month.isNull)
		    {
		     endDateStr ~= фильтрДатыКонец.day.isNull ? "" : фильтрДатыНачало.day.to!string ~ ` `;
		         if(фильтрДатыКонец.day.isNull)
		             endDateStr ~= фильтрДатыКонец.month.isNull ? " число любого месяца" : месяцы.getName(фильтрДатыКонец.month);
		         else  		    
		             endDateStr ~= фильтрДатыКонец.month.isNull ? " число любого месяца" : месяцы_родительный.getName(фильтрДатыКонец.month);
		    }
		endDateStr ~=` `~(фильтрДатыКонец.year.isNull ? " " : фильтрДатыКонец.year.to!string);
		}
		
	return (район~`<fieldset><legend>Сроки похода</legend> Начало похода `~beginDateStr ~`<br/> Конец похода  `~endDateStr~`</fieldset>`);
}

//-----------------------------------------------------------------------------

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	
	bool isForPrint = rq.bodyForm.get("for_print", null) == "on";//если on то true форма для печати
	
	string content;
	
	//Создаём подключение к БД
	auto dbase = getCommonDB();
		
	//string параметрыПоиска;//контроль изменения парамнтров фильтрации
	//string параметрыПоиска_старое = rq.bodyForm.get("параметрыПоиска", "");
	
// 	bool естьФильтрация;    // котроль необходимости фильтрации
	bool _sverka = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	
	ФильтрПоходов фильтрПоходов = получитьФильтрПоходов(context);
	
	string строкаЗапроса_фильтрыПохода = получитьЧастьЗапроса_фильтрПоходов(фильтрПоходов);
	
	string запросКоличестваПоходов = `select count(1) from pohod`;
 	
	if( фильтрПоходов.естьФильтрация )
		запросКоличестваПоходов ~= ` where ` ~ строкаЗапроса_фильтрыПохода; 
		
	uint limit;	
		
	if (isForPrint)//для печати 
	limit=10000;// максимальное  число строк на странице	
	else	
	limit = 10;// максимальное  число строк на странице
	
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

	string pageSelector;// окна выбора страницы
	 pageSelector ~= `<table class="ou_print"><tr><td style='width: 100px;'>`;
	if (isForPrint)
	{
	 pageSelector ~=` <a href='javascript:window.print(); void 0;' class="noprint" > <img  height="60" width="60"  class="noprint"   src="/pub/img/icons/printer.png" /></a> <!-- печать страницы -->`
	 ~ "</td><td>"~ "\r\n"
	 
	 ;
	}
	else
	{
	
	// окна выбора страницы
	
	pageSelector ~=( (curPageNum > 1) ? `<a href="#" onClick="gotoPage(` ~ (curPageNum - 1).to!string ~ `)">Предыдущая</a>` : "" )
	
	~ "</td><td>"~ "\r\n"
	~ ` Страница <input name="cur_page_num" type="text" size="4" maxlength="4" value="` ~ curPageNum.to!string ~ `"> из ` 
	~ pageCount.to!string ~ ` <input type="submit" value="Перейти"> `
	~ "</td><td>" ~ "\r\n"
	~ ( (curPageNum < pageCount ) ? `<a href="#" onClick="gotoPage(` ~ (curPageNum + 1).to!string ~ `)">Следующая</a>` : "")
		~ "\r\n";
		}
	  pageSelector ~= `&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`;
	 
	 if (isForPrint)//для печати
	      pageSelector ~=` <button name="for_print" type="submit"  class="noprint" > Назад </button>`;
	   else	     
	      pageSelector ~=` <button name="for_print" type="submit"  value="on"  > Для печати </button>`;
	 
	 pageSelector ~=   "</td></tr></table>"~ "\r\n";    
	 
	// Начало формирования основной отображающей таблицы  
	string table = `<table class="tab1"    >`;
	
	table ~= "<tr>";
	if(_sverka)
		table ~= `<th>#</th>`~ "\r\n";// появляется при наличии допуска
	
	table ~= `<th>№ книги</th><th>Сроки похода</th><th>Вид, категория</th><th>Район</th><th>Руководитель</th><th>Участники</th><th>Город, организация</th><th>Статус похода</th>` ~ "\r\n";
	
	if(_sverka) table ~=`<th>Изм.</th>`~ "\r\n";// появляется при наличии допуска
	table ~= "</tr>";
	
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
		~ (  rec.get!"Число участников"("Не задано") ) ~ `<img class="noprint" src="` ~ imgPath ~ `icons/list_icon.png">`
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
	table ~= "</table>\r\n";
	
	
  if (isForPrint)	//для печати 
	content ~= `<link rel="stylesheet" type="text/css" href="` ~ cssPath ~ `page_styles.css">`~ "\r\n";
	//content ~=поисковый_диапозон_Походов(фильтрПоходов)~ "\r\n";
	content ~= `<form id="main_form" method="post">`~ "\r\n";// содержимое страницы
	
	if (isForPrint)//для печати
	   {
		content ~=`<fieldset><legend>Поисковые фильтры</legend>`
		~отрисоватьБлокФильтрации_для_печати(фильтрПоходов)  
		~`</span></fieldset>`~ "\r\n";
		content ~=поисковый_диапозон_Походов(фильтрПоходов)~ pageSelector~ `</form><br>`~ "\r\n";
		}
	else
		content ~= отрисоватьБлокФильтрации(фильтрПоходов) ~ pageSelector ~ `</form><br>`~ "\r\n";
		
	content ~=( _sverka ? `<a href="` ~ dynamicPath ~ `edit_pohod">Добавить новый поход</a><br>` ~ "\r\n" : "" )
	~ `<p> Число походов ` ~ количествоПоходов.to!string ~ ` </p>`~ "\r\n"
	~ table; //Тобавляем таблицу с данными к содержимому страницы
	
	//Подключение JavaScript файла с именем, указанным в атрибуте src
	content ~= `<script src="` ~ jsPath ~ "show_pohod.js" ~ `"></script>`;
	
	return content;
}
