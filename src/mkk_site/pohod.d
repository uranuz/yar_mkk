module mkk_site.pohod;

import std.conv, std.string, std.utf, std.typecons;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "pohod";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{
	auto req = context.request;
	
	auto queryForm = req.queryForm;
	bool isAuthorized = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );
	
	size_t pohodKey;

	if( queryForm.get("key", null).empty )
	{
		static immutable errorMsg = `<h3>Невозможно отобразить данные похода. Номер похода не задан</h3>`;
		SiteLoger.error( errorMsg );
		return errorMsg;
	}

	try
	{
		pohodKey = queryForm.get("key", null).to!size_t;
	}
	catch( ConvException e )
	{
		static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер похода должен быть целым числом</h3>`;
		SiteLoger.error( errorMsg2 );
		return errorMsg2;
	}

	auto pohodRecord = getPohodInfo(pohodKey);
	auto touristList = getPohodParticipants(pohodKey);
	auto extraFileList = getExtraFileLinks(pohodKey);
	
	static struct ViewModel
	{
		size_t pohodKey;
		typeof(pohodRecord) pohodRec;
		typeof(touristList) touristsRS;
		typeof(extraFileList) extraLinkList;
		bool isAuthorized;
	}
	
	ViewModel vm = ViewModel(
		pohodKey,
		pohodRecord,
		touristList,
		extraFileList,
		isAuthorized
	);

	return renderPohodPage(vm);
}

static immutable touristRecFormat = RecordFormat!(
	string, "ФИО и год"
)();

auto getPohodParticipants(size_t pohodKey)
{
	string queryStr =
`with tourist_nums as (
	select unnest(unit_neim) as num from pohod where pohod.num = ` ~ pohodKey.to!string ~ `
)
select coalesce(family_name, '') || coalesce( ' ' || given_name, '' )
	||coalesce(' '||patronymic, '')||coalesce(', '||birth_year::text,'') from tourist_nums 
left join tourist
	on tourist.num = tourist_nums.num
`;

	return getCommonDB()
		.query(queryStr)
		.getRecordSet(touristRecFormat);
}

string renderPohodPage(VM)( ref VM vm )
{
	if( vm.pohodRec is null )
	{
		string errorMsg = `<h3>Невозможно отобразить данные похода с номером ` ~ vm.pohodKey.text ~ `. Поход не найден</h3>`;
		SiteLoger.error( errorMsg );
		return errorMsg;
	}

	auto tpl = getPageTemplate( pageTemplatesDir ~ "pohod.html" );
	
	FillAttrs fillAttrs;
	fillAttrs.defaults = [
		"Маршрут": `Сведения отсутствуют`,
		"Комментарий руководителя": `Не задано`,
		"Комментарий МКК": `Не задано`
	];
	
	tpl.fillFrom( vm.pohodRec, fillAttrs );

	tpl.set( "tourist_list", renderPohodParticipants(vm) );
	tpl.set( "file_link_list", renderExtraFileLinks(vm) );

	if( vm.isAuthorized && !vm.pohodRec.isNull("Ключ")  )
	{
		tpl.set( "edit_btn_href", dynamicPath ~ "edit_pohod?key=" ~ vm.pohodRec.getStr!"Ключ"(null) );
	}
	else
	{
		tpl.set( "edit_btn_cls", "is-hidden" );
	}

	return tpl.getString();
}

string renderExtraFileLinks(VM)( ref VM vm )
{
	auto tpl = getPageTemplate( pageTemplatesDir ~ "pohod_extra_file_link.html" );
	
	string extraFilesList;

	if( vm.extraLinkList.length )
	{
		foreach( rec; vm.extraLinkList )
		{
			tpl.setHTMLValue( "uri_input_value", rec.uri );
			tpl.setHTMLValue( "descr_input_value", rec.descr );

			extraFilesList ~= tpl.getString();
		}
	}
	else
	{
		extraFilesList = `Нет данных`;
	}

	return extraFilesList;
}

string renderPohodParticipants(VM)( ref VM vm )
{
	if( vm.touristsRS is null )
	{
		string errorMsg = `Не удалось получить список участников похода с номером ` ~ vm.pohodKey.text;
		SiteLoger.error(errorMsg);
		return errorMsg;
	}

	auto tpl = getPageTemplate( pageTemplatesDir ~ "pohod_tourist_item.html" );
	
	FillAttrs fillAttrs;
	
	string touristList;
	
	foreach( rec; vm.touristsRS )
	{
		tpl.fillFrom( rec, fillAttrs );
		touristList ~= tpl.getString().dup;
	}
	
	return touristList;
}
