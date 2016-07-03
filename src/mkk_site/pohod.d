module mkk_site.pohod;

import std.conv, std.string, std.utf, std.typecons;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "pohod";
	PageRouter.join!(netMain)(thisPagePath);
}

string participantsList( size_t pohodNum ) //функция получения списка участников
{
	auto rs = getPohodParticipants( pohodNum );
	
	static struct VM { typeof(rs) touristsRS; }
	VM vm = VM(rs);
	
	if( rs.length )
		return renderPohodParticipants(vm);
	else
		return `Сведения об участниках <br> отсутствуют`;
}

string linkList( size_t pohodNum ) //функция получения списка ссылок
{
	auto dbase = getCommonDB();
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
	bool isAuthorized = context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );
	
	size_t pohodKey;
	try {
		pohodKey = qVars.get("key", "0").to!size_t;
	}
	catch(std.conv.ConvException e)
	{	pohodKey = 0; }
	
	
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

static immutable pohodInfoQueryBase =
`select
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
	chef,
	alt_chef,
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

static immutable pohodRecFormat = RecordFormat!(
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
	size_t, "Номер рук.",
	size_t, "Номер зам. рук.",
	string, "Руководитель",
	string, "Заместитель рук.",
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

auto getPohodInfo(size_t pohodKey)
{
	string queryStr = pohodInfoQueryBase ~ ` where pohod.num = ` ~ pohodKey.to!string ~ `;`;
	auto rs = getCommonDB().query(queryStr).getRecordSet(pohodRecFormat);
	
	if( rs && rs.length == 1 )
		return rs.front;
	else
		return null;
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

	if( vm.pohodRec && vm.isAuthorized && !vm.pohodRec.isNull("Ключ")  )
	{
		tpl.set( "edit_btn_href", dynamicPath ~ "edit_pohod?key=" ~ vm.pohodRec.getStr!"Ключ"(null) );
	}
	else
	{
		tpl.set( "edit_btn_cls", "is-hidden" );
	}

	
	return tpl.getString();
}

static immutable extraFileLinkRecordFormat = RecordFormat!(
	string, "Ссылка"
)();

import std.typecons: Tuple;

alias ExtraFileLink = Tuple!( string, "uri", string, "descr" );

auto getExtraFileLinks( size_t pohodKey )
{
	string queryStr = 
	`select unnest(links) as num from pohod where pohod.num = ` ~ pohodKey.to!string;
	
	auto rs = getCommonDB()
		.query(queryStr)
		.getRecordSet(extraFileLinkRecordFormat);
	
	ExtraFileLink[] links;
	links.length = rs.length;
	
	size_t i = 0;
	foreach( rec; rs )
	{
		string[] linkPair = parseExtraFileLink( rec.get!"Ссылка"(null) );
		links[i].uri = linkPair[0];
		links[i].descr = linkPair[1];
		
		++i;
	}
	
	return links;
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
	auto tpl = getPageTemplate( pageTemplatesDir ~ "pohod_tourist_item.html" );
	
	FillAttrs fillAttrs;
	
	string touristList;
	
	//foreach( rec; vm.touristsRS )
	for( size_t i = 0; i < vm.touristsRS.length ; ++i )
	{
		tpl.fillFrom( vm.touristsRS[i], fillAttrs );
		touristList ~= tpl.getString().dup;
	}
	
	return touristList;
}