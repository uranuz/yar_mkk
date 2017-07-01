module mkk_site.main_service.tourist_list;

import std.conv, std.string, std.utf;

import mkk_site.main_service.devkit;

import mkk_site.site_data;

import std.stdio;

//***********************Обявление метода*******************
shared static this()
{
	Service.JSON_RPCRouter.join!(touristSet)(`tourist.Set`);
	
}
//**********************************************************

	



import std.typecons: tuple;

/// Формат записи для списка туристов сайта
static immutable touristListRecFormat = RecordFormat!(
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

/*struct TouristFilter
{
	Optional!string familyName;
	Optional!string givenName;
	Optional!string patronymic;
	Optional!int birthYear;

}*/

//--------------------------------------------------------
import std.json;

  JSONValue touristSet
	(
		HTTPContext context,
		//TouristFilter filter,
		string familyName,
		string givenName,
		string patronymic,	
		//size_t TouristCount,//число строк
		//size_t pageCount,   // число страниц
		size_t currentPage  //текущая страница
	)
	{	
	
		/*	

 (	HTTPContext context)

	if( context.user.isAuthenticated ) {
		// Вход выполнен
	}
	
	
	
	if( context.user.isInRole("moder") ) {
		// Пользователь - модератор
	}
	
	if( context.user.isInRole("moder") || context.user.isInRole("admin") )
	{
		// Пользователь - модератор или админ
	}
	*/
	
	
	
	bool isAuthorized 
			= context.user.isAuthenticated && ( context.user.isInRole("admin") || context.user.isInRole("moder") );
	


static immutable touristListQ =
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
from tourist  `;

size_t limit = 10; // Число строк на странице

	//qualification

			import std.array: join;
			import std.range: empty;

	string[] filters;

	if( !familyName.empty )
		filters ~= `family_name ILIKE '%` ~ familyName ~ `%'`;

	if( !givenName.empty )
		filters ~= `given_name ILIKE '` ~ givenName ~ `%'`;

	if( !patronymic.empty )
		filters ~= `patronymic ILIKE '` ~ patronymic ~ `%'`;
		
		string filtr= ( filters.empty ? "" : ` where ` ~ filters.join(" and ") );
	
	
//-----Число строк туристов-------

	string queryStr = `select count(1) from tourist` ~  filtr  ;
	
	size_t TouristCount = getCommonDB()
								.query(queryStr)
								.get(0, 0, "0").to!size_t;


//---------------------------------------------
		
		size_t pageCount = TouristCount/ limit + 1; //Количество страниц
		
		if(currentPage>pageCount) currentPage=pageCount; //текущая страница
		//если номер страницы больше числа страниц переходим на последнюю 
			
		if(currentPage<1) currentPage=1; //текущая страница
		//если номер страницы меньше 1 переходим на первую 
			
			
		


	
		
	 size_t offset = (currentPage - 1) * limit ; //Сдвиг по числу записей
		
	string touristListQuery //запрос содержание таблицы
			=touristListQ
			~ ( filtr  )
			~ ` order by num LIMIT `~ limit.to!string
			~ ` OFFSET `~ offset.to!string ~` `
			;
	
	
		//writeln(currentPage());
		//writeln(offset.to!string);

	auto touristTabl = getCommonDB()
							.query(touristListQuery)
							.getRecordSet(touristListRecFormat);

//---------Сборка из всех данных---
		JSONValue TourristSet;
		  
			TourristSet["touristCount"]= TouristCount ;
			TourristSet["pageCount"]   = pageCount;
			TourristSet["currentPage"]  = currentPage;
			TourristSet["familyName"]  = familyName;
			TourristSet["givenName" ]  = givenName;
			TourristSet["patronymic"]  = patronymic;
			TourristSet["isAuthorized"]  = isAuthorized;
			TourristSet["touristTabl"] =touristTabl.toStdJSON();
			
			//isAuthorized

			writeln(familyName);
			
		  
		return TourristSet;
	}
	
	
	
	
	