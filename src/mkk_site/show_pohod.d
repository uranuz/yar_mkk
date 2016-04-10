module mkk_site.show_pohod;

import std.conv, std.string, std.array, std.stdio;
import std.exception : ifThrown;
import std.file; //Стандартная библиотека по работе с файлами
//import webtank.db.database;
import 
	webtank.datctrl.data_field, 
	webtank.datctrl.record_format, 
	webtank.db.postgresql, 
	webtank.db.datctrl_joint, 
	webtank.datctrl.record, 
	webtank.templating.plain_templater, 
	webtank.net.http.context, 
	webtank.templating.plain_templater_datctrl;

import webtank.common.optional;
import webtank.common.conv;

import webtank.ui.list_control: checkBoxList;
import webtank.ui.date_picker: PlainDatePicker;
import webtank.net.utils: HTMLEscapeValue, PGEscapeStr;

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

/////////////////////////////////////

string отрисоватьБлокФильтрации(ФильтрПоходов фильтрПоходов)
{
	auto списокВидовТуризма = checkBoxList(видТуризма);
	with( списокВидовТуризма )
	{
		nullText = "любой";
		dataFieldName = "vid";
		selectedValues = фильтрПоходов.видыТуризма;
		addElementClasses("list_wrapper", `b-pohod_filter_vid e-block`);
	}
	
	auto списокКатегорий = checkBoxList(категорияСложности);
	with( списокКатегорий )
	{
		nullText = "любая";
		dataFieldName = "ks";
		selectedValues = фильтрПоходов.категории;
		addElementClasses("list_wrapper", `b-pohod_filter_ks e-block`);
	}
	
	auto списокГотовностей = checkBoxList(готовностьПохода);
	with( списокГотовностей )
	{
		nullText = "любой";
		dataFieldName = "prepar";
		selectedValues = фильтрПоходов.готовности;
		addElementClasses("list_wrapper", `b-pohod_filter_prepar e-block`);
	}
	
	auto списокСтатусовЗаявки = checkBoxList(статусЗаявки);
	with( списокСтатусовЗаявки )
	{
		nullText = "любой";
		dataFieldName = "stat";
		selectedValues = фильтрПоходов.статусыЗаявки;
		addElementClasses("list_wrapper", `b-pohod_filter_stat e-block`);
	}
	
	auto формаФильтрации = getPageTemplate( pageTemplatesDir ~ "pohod_filter_form.html" );
	
	foreach( имяПоля, дата; фильтрПоходов.сроки )
	{
		auto полеДаты = new PlainDatePicker;
		полеДаты.dataFieldName = имяПоля;
		полеДаты.date = дата;
		полеДаты.nullDayText = "день";
		полеДаты.nullMonthText = "месяц";
		полеДаты.nullYearText = "год";
		
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
		foreach( вид; фильтрПоходов.видыТуризма )
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
	if (фильтрПоходов.категории.length)
	{
		foreach( кс; фильтрПоходов.категории )
		{
			if( категорияСложности.hasValue(кс) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиКС ~= категорияСложности.getName(кс);
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
	if (фильтрПоходов.готовности.length)
	{
		foreach( гп; фильтрПоходов.готовности )
		{	
			if( готовностьПохода.hasValue(гп) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиПодготовка ~= готовностьПохода.getName(гп);
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
	if (фильтрПоходов.статусыЗаявки.length)
	{
		foreach( сз; фильтрПоходов.статусыЗаявки )
		{	
			if( статусЗаявки.hasValue(сз) ) //Проверяет наличие значения в перечислимом типе
			{
				строкиЗаявка ~= статусЗаявки.getName(сз);
			}
		}
	}
	else
	{
		строкиЗаявка ~= "Все походы";
	}	
	
	string списокЗаявка = строкиЗаявка.join(",<br>");
	
	//----------------------------------------------------
	
	auto формаФильтрации = getPageTemplate( pageTemplatesDir ~ "pohod_filter_print.html" );
	
	foreach( имяПоля, дата; фильтрПоходов.сроки )
	{
		auto полеДаты = new PlainDatePicker;
		полеДаты.dataFieldName = имяПоля;
		полеДаты.date = дата;
		полеДаты.nullDayText = "день";
		полеДаты.nullMonthText = "месяц";
		полеДаты.nullYearText = "год";
		
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
string getPohodFilterQueryPart(ref const(ФильтрПоходов) фильтрПоходов)
{
	import std.datetime: Date;
	
	string[] filters;
	
	if( фильтрПоходов.видыТуризма.length > 0 )
		filters ~= `vid in(` ~ фильтрПоходов.видыТуризма.conv!(string[]).join(", ") ~ `)`;
	
	if( фильтрПоходов.категории.length > 0 )
		filters ~= `ks in(` ~ фильтрПоходов.категории.conv!(string[]).join(", ") ~ `)`;
		
	if( фильтрПоходов.готовности.length > 0 )
		filters ~= `prepar in(` ~ фильтрПоходов.готовности.conv!(string[]).join(", ") ~ `)`;
		
	if( фильтрПоходов.статусыЗаявки.length > 0 )
		filters ~= `stat in(` ~ фильтрПоходов.статусыЗаявки.conv!(string[]).join(", ") ~ `)`;
	
	if( фильтрПоходов.сМатериалами )
		filters ~= `(array_length(links, 1) != 0 AND array_to_string(links, '', '')!= '')`;
	
	string[] dateFiilters;
	
	static immutable назвЧастейДаты = [ "year", "month", "day" ];
	
	foreach( соотвПоля; соотвПолейСроков )
	{
		OptionalDate фильтрДаты = фильтрПоходов.сроки[ соотвПоля.имяВФорме ];
		
		if( фильтрДаты.isDefined )
		{
			dateFiilters ~= ` ('` ~ Date( фильтрДаты.tupleof ).conv!string ~ `'::date ` 
				~ соотвПоля.опСравн ~ ` ` ~ соотвПоля.имяВБазе ~ `) `;
		}
		else
		{
			foreach( j, частьДаты; фильтрДаты.tupleof )
			{
				if( !частьДаты.isNull )
				{
					dateFiilters ~= частьДаты.conv!string ~ ` `
						~ соотвПоля.опСравн ~ ` date_part('` ~ назвЧастейДаты[j] ~ `', ` ~ соотвПоля.имяВБазе ~ `)`;
				}
			}
		}
	}
	
	filters ~= dateFiilters;
	
	if( фильтрПоходов.районПохода.length > 0 )
		filters ~= `region_pohod ILIKE '%` ~ фильтрПоходов.районПохода ~ `%'`;
	
	return ( filters.length > 0 ?
		" ( " ~ filters.join(" ) and ( ") ~ " ) " : null );
}
//-------------------------------------------------------------

// -------Формирует информационную строку о временном диапозоне поиска походов
string поисковый_диапазон_Походов(const ref ФильтрПоходов фильтрПоходов)
{
	import std.datetime: Date;
	
	OptionalDate фильтрДатыНачало = фильтрПоходов.сроки[ "begin_date_range_head" ];
	OptionalDate фильтрДатыКонец = фильтрПоходов.сроки[ "end_date_range_tail" ];
	//writeln(фильтрДатыНачало);
	//writeln(фильтрДатыКонец);
	string[] _месяцы = ["января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря"];
	string район;
	string beginDateStr;
	string endDateStr;
	
	if( фильтрПоходов.районПохода != "" ) район ~= "<br/>Район похода содержит [ " ~ фильтрПоходов.районПохода ~ " ].<br/>";
	if( фильтрПоходов.сМатериалами ) район ~= " По данным походам имеются отчёты или дополнительные материалы.<br/><br/>";
	
	if(фильтрДатыНачало.isNull) beginDateStr~=" не определено";
	else
	{
		if(  !фильтрДатыНачало.day.isNull || !фильтрДатыНачало.month.isNull)
		{
			beginDateStr ~= фильтрДатыНачало.day.isNull ? "" : фильтрДатыНачало.day.to!string ~ ` `;
			if(фильтрДатыНачало.day.isNull)
				beginDateStr ~= фильтрДатыНачало.month.isNull ? "число любого месяца" : месяцы.getName(фильтрДатыНачало.month);
			else 		          
				
				beginDateStr ~= фильтрДатыНачало.month.isNull ? "число любого месяца" : месяцы_родительный.getName(фильтрДатыНачало.month);
		}
		beginDateStr ~= ` ` ~ (фильтрДатыНачало.year.isNull ? "" : фильтрДатыНачало.year.to!string);
	}
	
	if( фильтрДатыКонец.isNull )
		endDateStr~=" не определён ";
	else
	{ 
		if( !фильтрДатыКонец.day.isNull || !фильтрДатыКонец.month.isNull )
		{
			endDateStr ~= фильтрДатыКонец.day.isNull ? "" : фильтрДатыНачало.day.to!string ~ ` `;
			if( фильтрДатыКонец.day.isNull )
				endDateStr ~= фильтрДатыКонец.month.isNull ? " число любого месяца" : месяцы.getName(фильтрДатыКонец.month);
			else
				endDateStr ~= фильтрДатыКонец.month.isNull ? " число любого месяца" : месяцы_родительный.getName(фильтрДатыКонец.month);
		}
		endDateStr ~= ` ` ~ ( фильтрДатыКонец.year.isNull ? " " : фильтрДатыКонец.year.to!string );
	}
		
	return (район~`<fieldset><legend>Сроки похода</legend> Начало похода `~beginDateStr ~`<br/> Конец похода  `~endDateStr~`</fieldset>`);
}

//-----------------------------------------------------------------------------

import std.typecons: tuple;

static immutable pohodRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "Ключ", 
	string, "Номер книги", 
	string, "Сроки", 
	typeof(видТуризма), "Вид", 
	typeof(категорияСложности), "КС", 
	typeof(элементыКС), "Элем КС",
	string,"Район",
	string,"Руководитель", 
	string, "Число участников",
	string,"Организация",
	string, "Маршрут",
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

private static immutable pohodListQueryPart =
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
	coalesce(marchrut::text, '') as marchrut, 
	prepar,
	stat 
from pohod 
LEFT OUTER JOIN t_chef
	on t_chef.num = pohod.num
`;

size_t getPohodCount(ФильтрПоходов filter)
{
	string query = `select count(1) from pohod`;
	
	if( filter.естьФильтрация )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);
	
	 return getCommonDB()
		.query(query)
		.get(0, 0, "0").to!size_t;
}

auto getPohodList(ФильтрПоходов filter, size_t offset, size_t limit )
{
	string query = pohodListQueryPart;
	
	if( filter.естьФильтрация )
		query ~= ` where ` ~ getPohodFilterQueryPart(filter);
		
	query ~= ` order by pohod.begin_date desc offset ` ~ offset.to!string ~ ` limit ` ~ limit.to!string;
	
	 return getCommonDB()
		.query(query)
		.getRecordSet(pohodRecFormat);
}

string renderShowPohod(VM)( ref VM vm )
{
	auto tpl = getPageTemplate( pageTemplatesDir ~ "show_pohod.html" );
	
	tpl.set( "pohod_count", vm.pohodCount.text );
	
	tpl.set( "pohod_list_pagination", renderPaginationTemplate(vm) );
	
	if( !vm.isAuthorized )
	{
		tpl.set( "pohod_num_col_header_cls", "is-hidden" );
		tpl.set( "edit_pohod_col_header_cls", "is-hidden" );
	}
	
	if( vm.isForPrint )
	{
		tpl.set( "pohod_filter_regular_cls", "is-hidden" );
		tpl.set( "pohod_filter_for_print", 
			отрисоватьБлокФильтрации_для_печати(vm.filter)
			~ поисковый_диапазон_Походов(vm.filter)
		);
		tpl.set( "print_switch_btn_text", "Назад" );
		tpl.set( "print_switch_btn_cls", "noprint" );
	}
	else
	{
		tpl.set( "pohod_filter_for_print_cls", "is-hidden" );
		tpl.set( "pohod_filter_regular", отрисоватьБлокФильтрации(vm.filter) );
		tpl.set( "print_switch_btn_text", "Для печати" );
		tpl.set( "print_switch_btn_value", "on" );
	}
	
	tpl.set( "pohod_list", renderPohodList(vm) );
	
	return tpl.getString();
}

string renderPohodList(VM)( ref VM vm )
{
	auto pohodTpl = getPageTemplate( pageTemplatesDir ~ "show_pohod_item.html" );
	
	FillAttrs fillAttrs;
	fillAttrs.noEscaped = [ "Номер книги", "Сроки", "Руководитель", "Организация" ];
	//fillAttrs.defaults = [];
	
	string content;
	
	foreach(rec; vm.pohodsRS)
	{
		pohodTpl.fillFrom(rec, fillAttrs);
		
		if( vm.isAuthorized )
		{
			string pohodKey = rec.isNull("Ключ") ? "" : rec.get!"Ключ"().text;
			pohodTpl.set( "Колонка ключ",  `<td>` ~ pohodKey ~ `</td>` );
			pohodTpl.set( "Колонка изменить", `<td><a href="` ~ dynamicPath ~ `edit_pohod?key=`
				~ pohodKey ~ `">Изменить</a></td>` );
		}
		
		content ~= pohodTpl.getString();
	}
	
	return content;
}


string netMain(HTTPContext context)
{	
	auto rq = context.request;
	
	bool isForPrint = rq.bodyForm.get("for_print", null) == "on";//если on то true форма для печати
	//string параметрыПоиска;//контроль изменения парамнтров фильтрации
	//string параметрыПоиска_старое = rq.bodyForm.get("параметрыПоиска", "");
	
// 	bool естьФильтрация;    // котроль необходимости фильтрации
	bool isAuthorized = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );    // наличие сверки
	ФильтрПоходов фильтрПоходов = получитьФильтрПоходов(context);
	size_t pohodsPerPage;
	
	if( isForPrint ) //для печати 
		pohodsPerPage = 10000; // максимальное  число строк на странице	
	else
		pohodsPerPage = 10; // максимальное  число строк на странице
	
	size_t pohodCount = getPohodCount( фильтрПоходов );
	
	size_t pageCount = pohodCount / pohodsPerPage+1; //Количество страниц
	size_t curPageNum = rq.bodyForm.get("cur_page_num", "1").to!(size_t).ifThrown!ConvException(1); //Номер текущей страницы
	
	if( curPageNum > pageCount ) curPageNum = pageCount; 
	//если номер страницы больше числа страниц переходим на последнюю 
	//?? может лучше на первую

	//if( параметрыПоиска_старое != параметрыПоиска ) curPageNum = 1;
	//если параметры поиска изменились переходим на 1-ю страницу
	
	size_t offset = (curPageNum - 1) * pohodsPerPage ; //Сдвиг по числу записей
	
	auto pohodsList = getPohodList( фильтрПоходов, offset, pohodsPerPage );
	auto tpl = getPageTemplate( pageTemplatesDir ~ "show_pohod.html" );
	
	static struct ViewModel
	{
		typeof(pohodsList) pohodsRS; //RecordSet
		bool isAuthorized;
		bool isForPrint;
		size_t curPageNum;
		size_t pohodCount;
		size_t pohodsPerPage;
		size_t pageCount;
		ФильтрПоходов filter;
	}
	
	ViewModel vm = ViewModel(
		pohodsList,
		isAuthorized,
		isForPrint,
		curPageNum,
		pohodCount,
		pohodsPerPage,
		pageCount,
		фильтрПоходов
	);
	
	return renderShowPohod(vm);
}
