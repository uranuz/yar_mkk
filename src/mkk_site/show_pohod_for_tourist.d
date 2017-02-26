module mkk_site.show_pohod_for_tourist;

import std.conv, std.string, std.utf, std.typecons, std.json;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;
static immutable size_t pohodsPerPage = 10;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_pohod_for_tourist";
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(getPohodsForTourist);
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
		static immutable errorMsg = "<h3>Не задан корректный идентификатор туриста</h3>";
		SiteLoger.error( errorMsg );
		return errorMsg;
	}
	
	size_t curPageNum = 1; //Номер текущей страницы
		
	try {
		curPageNum = req.bodyForm.get("cur_page_num", "1").to!size_t;
	} catch( std.conv.ConvException e ) { curPageNum = 1; }
	
	string content;
	
	bool isAuthorized = user.isAuthenticated && ( user.isInRole("admin") || user.isInRole("moder") );
	auto touristInfo = TouristInfo.getTouristInfo(touristKey);
	
	size_t pohodCount = TouristInfo.getPohodCount(touristKey.value);
	size_t pageCount = pohodCount / pohodsPerPage + 1;
	
	if( curPageNum == 0 || curPageNum > pageCount )
		curPageNum = 1;
	
	auto pohodsList = TouristInfo.getPohodsList(
		touristKey.value, curPageNum, pohodsPerPage
	);
	
	static struct ViewModel
	{
		typeof(pohodsList) pohodsRS; //RecordSet
		typeof(touristInfo) touristRec; //Record
		size_t touristKey;
		bool isAuthorized;
		size_t curPageNum;
		size_t pohodCount;
		size_t pohodsPerPage;
		size_t pageCount;
	}
	
	ViewModel vm = ViewModel(
		pohodsList,
		touristInfo,
		touristKey.value,
		isAuthorized,
		curPageNum,
		pohodCount,
		pohodsPerPage,
		pageCount
	);
	
	return TouristInfoView.renderTouristProps(vm);
}

JSONValue getPohodsForTourist( HTTPContext context, size_t touristKey, size_t curPageNum )
{
	JSONValue vm;
	
	auto user = context.user;
	
	vm["isAuthorized"] = user.isAuthenticated && ( user.isInRole("admin") || user.isInRole("moder") );
	vm["pohodsRS"] = 
		TouristInfo.getPohodsList( touristKey, curPageNum, pohodsPerPage )
		.getStdJSON();
	vm["dynamicPath"] = dynamicPath;
	vm["touristKey"] = touristKey;
	
	return vm;
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

class TouristInfoView
{
public:
	static string renderTouristProps(VM)(ref VM vm)
	{
		if( vm.touristRec is null )
		{
			return `<p>Не удалось получить информацию по туристу</p>`;
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
		
		tpl.fillFrom( vm.touristRec, fillAttrs );
		
		if( vm.pohodCount == 0 )
		{
			tpl.set( "found_pohods_sect_cls", "is-hidden" );
		}
		else
		{
			tpl.set( "no_pohods_found_msg_cls", "is-hidden" );
		}
		
		tpl.set( "pohod_count", vm.pohodCount.text );
		tpl.set( "tourist_list_pagination", renderPaginationTemplate(vm) );
		
		if( !vm.isAuthorized )
		{
			tpl.set( "pohod_num_col_header_cls", "is-hidden" );
			tpl.set( "edit_pohod_col_header_cls", "is-hidden" );
		}
		
		tpl.set( "pohod_list", renderPohods(vm) );

		return tpl.getString();
	}
	
	static string renderPohods(VM)(ref VM vm)
	{
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
		
		string content;
			
		foreach(rec; vm.pohodsRS)
		{	
			pohodTpl.fillFrom(rec, pohodFillAttrs);

			string beginDate = rec.isNull("Дата начала") ? null : rec.get!"Дата начала"().rusFormat();
			string endDate = rec.isNull("Дата конца") ? null : rec.get!"Дата конца"().rusFormat();
			pohodTpl.set( "Сроки", beginDate ~ "<br>\r\n" ~ endDate );
			
			if( vm.isAuthorized )
			{
				string pohodKey = rec.isNull("Ключ") ? "" : rec.get!"Ключ"().text;
				pohodTpl.set( "Колонка ключ",  `<td>` ~ pohodKey ~ `</td>` );
				pohodTpl.set( "Колонка изменить", `<td><a href="` ~ dynamicPath ~ `edit_pohod?key=`
					~ pohodKey ~ `">Изменить</a></td>` );
			}

			pohodTpl.set( "Должность",
				vm.touristKey == rec.get!"Ключ рук"() ? `Руков` : `Участ`
			);

			content ~= pohodTpl.getString();
		}
	
		return content;
	}


}