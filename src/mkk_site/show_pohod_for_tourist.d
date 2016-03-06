module mkk_site.show_pohod_for_tourist;

import std.conv, std.string, std.utf, std.typecons;
import std.file;

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.templating.plain_templater_datctrl, webtank.net.http.context, webtank.common.optional;

import mkk_site;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_pohod_for_tourist";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{
	auto req = context.request;
	auto user = context.user;
	
	Optional!size_t touristKey;
	
	try {
		if( "key" in req.queryForm )
			touristKey = req.queryForm["key"].to!size_t;
	} catch( std.conv.ConvException e ) {  }
	
	if( touristKey.isNull )
	{
		return "Не задан корректный идентификатор туриста";
	}
	
	size_t curPageNum = 1; //Номер текущей страницы
		
	try {
		curPageNum = req.bodyForm.get("cur_page_num", "1").to!size_t;
	} catch( std.conv.ConvException e ) { curPageNum = 1; }
	
	string content;
	
	bool isAuthorized = user.isAuthenticated && ( user.isInRole("admin") || user.isInRole("moder") );
	auto touristInfo = TouristInfo.getTouristInfo(touristKey);
	content ~= TouristInfoView.renderTouristProps(touristInfo);
	
	size_t pohodCount = TouristInfo.getPohodCount(touristKey.value);
	size_t pohodsPerPage = 10;
	size_t pageCount = pohodCount / pohodsPerPage + 1;
	
	if( curPageNum == 0 || curPageNum > pageCount )
		curPageNum = 1;
	
	auto pohodsList = TouristInfo.getPohodsList(
		touristKey.value, curPageNum, pohodsPerPage
	);
	
	PohodListParams params;
	params.touristKey = touristKey.value;
	params.isAuthorized = isAuthorized;
	params.curPageNum = curPageNum;
	params.pohodCount = pohodCount;
	params.pohodsPerPage = pohodsPerPage;
	params.pageCount = pageCount;
	
	content ~= TouristInfoView.renderPohods( pohodsList, params );

	return content;
}

class TouristInfo
{
public:
	import std.datetime: Date;

	//получаем данные о ФИО и г.р. туриста
   static immutable touristRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Фамилия",
		string, "Имя",
		string, "Отчество",
		size_t, "Год рожд",
		string, "Опыт", 
		typeof(спортивныйРазряд), "Разряд", 
		typeof(судейскаяКатегория), "Категория",
		bool, "Показывать телефон",
		string, "Телефон",
		bool, "Показывать е-почту",
		string, "Е-почта",
		string, "Комментарий"
	)(
		null,
		tuple(
			спортивныйРазряд,
			судейскаяКатегория
		)
	);
	
	static immutable pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ",
		string, "Номер книги",
		Date, "Дата начала", 
		Date, "Дата конца",
		typeof(видТуризма), "Вид",
		typeof(категорияСложности), "КС",
		typeof(элементыКС), "Элем КС",
		size_t, "Ключ рук",
		string, "Организация",
		string, "Район",   
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
	
	static auto getTouristInfo(size_t touristKey)
	{
		string queryStr =
`
select 
	num,
	family_name, given_name, patronymic,
	birth_year,
	exp, razr, sud,
	show_phone, phone,
	show_email, email,
	comment
from tourist
where num = ` ~ touristKey.text ~ `;`;

		auto rs = getCommonDB().query(queryStr).getRecordSet(touristRecFormat);
			
		if( rs && !rs.empty )
			return rs.front;
		else
			return null;
	}

	static auto getPohodsList(size_t touristKey, size_t curPageNum, size_t pohodsPerPage)
	{
		size_t offset; //Сдвиг по числу записей
		
		if( curPageNum != 0 )
			offset = (curPageNum - 1) * pohodsPerPage ; //Сдвиг по числу записей
		
		string queryStr =
`
select
	num,
	( 
		coalesce(kod_mkk,'000-00') || '<br>' || 
		coalesce(nomer_knigi,'00-00')
	) as "Номер книги", 
	begin_date as "Дата начала",
	begin_date as "Дата конца",
	vid as "Вид",
	ks as "КС",
	elem as "Элем КС",
	chef_grupp as "Ключ рук",     
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as "Организация",
	region_pohod as "Район",
	coalesce(marchrut, '') as "Маршрут",
	prepar as "Готовность",
	stat as "Статус"
from pohod 
where ` ~ touristKey.text ~ ` = any( unit_neim )
order by begin_date desc
limit ` ~ pohodsPerPage.text ~ ` offset ` ~ offset.text ~ `;`;
	
	
		return getCommonDB()
			.query(queryStr)
			.getRecordSet(pohodRecFormat);
	}
	
	
	static size_t getPohodCount(size_t touristKey)
	{
		string queryStr =
`
select count(1) from pohod 
where ` ~  touristKey.text ~ ` = any( unit_neim );
`;

		auto queryRes = getCommonDB().query(queryStr);
		
		size_t pohodCount;
		
		if( queryRes.recordCount > 0 && queryRes.fieldCount > 0 )
			pohodCount = queryRes.get(0, 0, "0").to!size_t;
		
		return pohodCount;
	}


}

struct PohodListParams
{
	size_t touristKey;
	bool isAuthorized;
	size_t curPageNum;
	size_t pohodCount;
	size_t pohodsPerPage;
	size_t pageCount;
}

class TouristInfoView
{
public:
	static string renderTouristProps(Rec)(Rec rec)
	{
		string content = `<hr>` ~ "\r\n";
		
		if( rec is null )
		{
			content ~= `<p>Не удалось получить информацию по туристу</p>`;
			return content;
		}
		
		auto tpl = getPageTemplate(pageTemplatesDir ~ "show_pohod_for_tourist.html");
		FillAttrs fillAttrs;
		fillAttrs.defaults = [
			"Имя, день рожд": "",
			"Опыт": "не известно/см. список",
			"Разряд": "не известно",
			"Категория": "не известно",
			"Контакты": "нет",
			"Комментарий": ""
		];
		
		tpl.fillFrom(rec, fillAttrs);

		content ~= tpl.getString();
		
		return content;
	}
	
	static string renderPohods(RS)(RS rs, ref const(PohodListParams) params)
	{
		string content;
		
		if( params.pohodCount == 0 )
		{
			content ~= "Нет сведений о походах данного туриста";
			return content;
		}

		content ~=`<h2> Походов ` ~ params.pohodCount.text ~` </h2>`~ "\r\n";
		content ~= `<form id="main_form" method="post">`;
		
		auto paginTpl = getPageTemplate(pageTemplatesDir ~ "pagination.html");
		
		if( params.curPageNum <= 1 )
		{
			paginTpl.set( "prev_btn_cls", ".is-inactive_link" );
			paginTpl.set( "prev_btn_attr", `disabled="disabled"` );
		}
			
		paginTpl.set( "prev_page_num", (params.curPageNum - 1).text );
		paginTpl.set( "cur_page_num", params.curPageNum.text );
		paginTpl.set( "page_count", params.pageCount.text );
		paginTpl.set( "next_page_num", (params.curPageNum + 1).text );
		
		if( params.curPageNum >= params.pageCount )
		{
			paginTpl.set( "next_btn_cls", ".is-inactive_link" );
			paginTpl.set( "next_btn_attr", `disabled="disabled"` );
		}
		
		content ~= paginTpl.getString();
		
		content ~= "</form>\r\n";
		
		string table = `<table class="tab1">`;
	
		table ~= "<tr>";
		
		if( params.isAuthorized )
			table ~= `<th>#</th>`;
			
		table ~=
`<th>№ книги</th>
<th>Сроки похода</th>
<th>Вид, категория</th>
<th>Район</th>
<th>Роль в группе</th>
<th>Город, организация</th>
<th>Статус похода</th>` ~ "\r\n";
		
		if( params.isAuthorized ) 
			table ~= `<th>Изменить</th>` ~ "\r\n";
		table ~= "</tr>";
		
		table ~= `<tbody>`;
		
		auto pohodTpl = getPageTemplate(pageTemplatesDir ~ "pohod_for_tourist.html");
		FillAttrs pohodFillAttrs;
		pohodFillAttrs.noEscaped = [ "Номер книги", "Организация" ];
		pohodFillAttrs.defaults = [
			"Номер книги": "",
			"Вид": "не известно",
			"КС": "не известно",
			"Элем КС": "",
			"Организация": "нет",
			"Готовность": "не известно",
			"Статус": "не известно",
			"Маршрут": "не известно",
		];
			
		foreach(rec; rs)
		{	
			pohodTpl.fillFrom(rec, pohodFillAttrs);

			string beginDate = rec.isNull("Дата начала") ? null : rec.get!"Дата начала"().rusFormat();
			string endDate = rec.isNull("Дата конца") ? null : rec.get!"Дата конца"().rusFormat();
			pohodTpl.set( "Сроки", beginDate ~ "<br>\r\n" ~ endDate );
			
			if( params.isAuthorized )
			{
				string pohodKey = rec.isNull("Ключ") ? "" : rec.get!"Ключ"().text;
				pohodTpl.set( "Колонка ключ",  `<td>` ~ pohodKey ~ `</td>` );
				pohodTpl.set( "Колонка изменить", `<td><a href="` ~ dynamicPath ~ `edit_pohod?key=`
					~ pohodKey ~ `">Изменить</a></td>` );
			}

			pohodTpl.set( "Роль",
				params.touristKey == rec.get!"Ключ рук"() ? `Руков` : `Участ`
			);

			//`<td style="background-color:#8dc0de;" colspan="`;
			table ~= pohodTpl.getString();
		}
		table ~= `</tbody>`;
		table ~= `</table>` ~ "\r\n";
		
		content ~= table;
	
		return content;
	}


}