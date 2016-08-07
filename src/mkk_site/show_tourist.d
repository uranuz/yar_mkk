module mkk_site.show_tourist;

import std.conv, std.string, std.utf;

import mkk_site.page_devkit;

immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "show_tourist";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;

	bool isAuthorized = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );
	string familyName = PGEscapeStr( rq.bodyForm.get("family_name", null) );
	string givenyName = PGEscapeStr( rq.bodyForm.get("given_name", null) );
	string patronName = PGEscapeStr( rq.bodyForm.get("patronymic", null) );
	
	
	size_t limit = 10;
	
	size_t touristCount = getTouristCount(familyName,givenyName,patronName);// количество строк 
	
	size_t pageCount = touristCount / limit + 1; //Количество страниц
	size_t curPageNum = 1; //Номер текущей страницы
	
	//-----------------------
	try {
		if( "cur_page_num" in rq.bodyForm )// если в окне задан номер страницы
 			curPageNum = rq.bodyForm["cur_page_num"].to!size_t;
 			
	} catch (Exception) {}
	
	//-------------
	if(curPageNum>pageCount) curPageNum=pageCount; 
	//если номер страницы больше числа страниц переходим на последнюю 
	//?? может лучше на первую
	
	size_t offset = (curPageNum - 1) * limit ; //Сдвиг по числу записей
	

	auto touristList = getTouristList(familyName, givenyName, patronName, offset, limit);  //трансформирует ответ БД в RecordSet (набор записей)
	
	struct ViewModel
	{
		typeof(touristList) touristsRS;
		bool isAuthorized;
		string familyName;
		string givenyName;
		string patronName;
		size_t curPageNum;
		size_t touristsPerPage;
		size_t pageCount;
		size_t touristCount;
	}
	
	ViewModel vm = ViewModel(
		touristList,
		isAuthorized,
		familyName,
		givenyName,
		patronName,
		curPageNum,
		limit,
		pageCount,
		touristCount
	);
	
	return renderShowTourist(vm);
}

import std.typecons: tuple;

///Начинаем оформлять таблицу с данными
static immutable touristRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "Ключ", 
	string, "Имя и год рожд", 
	string,  "Опыт", 
	string, "Контакты",
	typeof(спортивныйРазряд),  "Разряд", 
	typeof(судейскаяКатегория), "Категория",
	string, "Комментарий"
)(
	null,
	tuple(спортивныйРазряд, судейскаяКатегория)
);

size_t getTouristCount(string familyName,string givenyName,string patronName)
{
	string queryStr = `select count(1) from tourist` 
		~ ( familyName.length == 0 ? "" : ` where family_name ILIKE '%` ~ familyName ~ `%'` )
		~ (` AND given_name ILIKE '` ~ givenyName ~ `%'`)
		~ (` AND patronymic ILIKE '` ~ patronName ~ `%'`);
	
	return getCommonDB()
		.query(queryStr)
		.get(0, 0, "0").to!size_t;
}

auto getTouristList(string familyName,string givenyName,string patronName, size_t offset, size_t limit)
{
	string queryStr =
`select 
	num, 
	( 
		coalesce(family_name, '') ||
		coalesce(' ' || given_name, '') ||
		coalesce(' ' || patronymic, '') ||
		coalesce(', ' || birth_year::text, '') 
	) as name,
	coalesce(exp, '???'), 
	( 
		case 
			when( show_phone = true ) then phone||'<br> ' 
		else '' end || 
		case 
			when( show_email = true ) then email 
		else '' end 
	) as contact,
	razr, sud, comment 
from tourist `
	~ ( familyName.length == 0 ? "" : ` WHERE family_name ILIKE '%` ~ familyName ~"%'" ) 
	~ (` AND given_name ILIKE '` ~ givenyName ~ `%'`)
	~ (` AND patronymic ILIKE '` ~ patronName ~ `%'`)
	~ ` order by num LIMIT `~ limit.to!string ~ ` OFFSET `~ offset.to!string ~` `; 
	
	return getCommonDB()
		.query(queryStr)
		.getRecordSet(touristRecFormat);
}

string renderTouristList(VM)( ref VM vm )
{
	auto touristTpl = getPageTemplate( pageTemplatesDir ~ "show_tourist_item.html" );
	
	FillAttrs fillAttrs;
	
	string content;
	
	foreach( rec; vm.touristsRS )
	{
		touristTpl.fillFrom(rec, fillAttrs);
		
		if( vm.isAuthorized )
		{
			string pohodKey = rec.isNull("Ключ") ? "" : rec.get!"Ключ"().text;
			touristTpl.set( "Колонка ключ",  `<td>` ~ pohodKey ~ `</td>` );
			touristTpl.set( "Колонка изменить", `<td><a href="` ~ dynamicPath ~ `edit_tourist?key=`
				~ pohodKey ~ `">Изменить</a></td>` );
		}
		
		content ~= touristTpl.getString();
	
	}

	return content;
}


string renderShowTourist(VM)( ref VM vm )
{
	auto tpl = getPageTemplate( pageTemplatesDir ~ "show_tourist.html" );
	
	tpl.set( "tourist_count", vm.touristCount.text );
	
	if( !vm.isAuthorized )
	{
		tpl.set( "tourist_num_col_header_cls", "is-hidden" );
		tpl.set( "edit_tourist_col_header_cls", "is-hidden" );
	}

	tpl.set( "auth_state_cls", vm.isAuthorized ? "m-with_auth" : "m-without_auth" );
	
	tpl.set( "tourist_list_pagination", renderPaginationTemplate(vm) );
	
	tpl.set( "tourist_list", renderTouristList(vm) );
	
	tpl.set( "family_name", vm.familyName );
	tpl.set( "given_name", vm.givenyName );
	tpl.set( "patronymic", vm.patronName );
	

	return tpl.getString();

}