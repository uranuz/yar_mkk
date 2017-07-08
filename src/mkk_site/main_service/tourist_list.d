module mkk_site.main_service.tourist_list;
import std.conv, std.string, std.utf;
import mkk_site.main_service.devkit;
import mkk_site.site_data;

import std.stdio;

//***********************Обявление метода*******************
shared static this()
{
	Service.JSON_RPCRouter.join!(touristSet)(`tourist.Set`);
	Service.JSON_RPCRouter.join!(touristSelected)(`tourist.Selected`);
}
//**********************************************************

struct DBName { string dbName; }

struct touristDataToWrite
{
	import webtank.common.optional: Undefable;
	import std.datetime: Date;
	Optional!size_t num; // туриста походе в базе

	// Секция "Маршрутная книжка"
	@DBName("family_name") Undefable!string familyName; // фамилия
	@DBName("given_name") Undefable!string givenName; // имя
	@DBName("patronymic") Undefable!string patronymic; // отчестао
	@DBName("brith_year") Undefable!int brithYear; // Статус заявки
	@DBName("adress") Undefable!string fdress; // отчестао
	@DBName("phone") Undefable!string phone; // телефон
	@DBName("show_phon") Undefable!bool showPhon; // отображать телефон
	@DBName("email") Undefable!string email; // email
	@DBName("show_email") Undefable!bool showEmail; // отображать email
	@DBName("exp") Undefable!string expirenc; // туристский опыт
	@DBName("comment") Undefable!string comment; // коментарий
	@DBName("razr") Undefable!int sportDischarge; // спортивный разряд
	@DBName("sud") Undefable!int refereeСategory; // судейская категория
}	



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
			
		if(currentPage<0) currentPage=0; //текущая страница
		//если номер страницы меньше 1 переходим на первую 
			
			
		


	
		
	 size_t offset = (currentPage ) * limit ; //Сдвиг по числу записей
		
	string touristListQuery //запрос содержание таблицы
			=touristListQ
			~ ( filtr  )
			~ ` order by num LIMIT `~ limit.to!string
			~ ` OFFSET `~ offset.to!string ~` `
			;
	
	
		writeln(currentPage);
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


struct TouristFilter
{
	import webtank.common.optional: Optional;

	@DBName("family_name") string familyName;
	@DBName("given_name") string givenName;
	@DBName("patronymic") string patronymic;
	@DBName("birth_year") Optional!int birthYear;
	@DBName("address") string region;
	@DBName("address") string city;
	@DBName("address") string street;
}

struct Navigation
{
	size_t offset = 0;
	size_t limit = 10;
} 

static immutable shortTouristRecFormat = RecordFormat!(
	PrimaryKey!(int), "num",
	string, "familyName",
	string, "givenName",
	string, "patronymic",
	int, "birthYear"
)();

	
	//RPC метод для вывода списка туристов (с краткой информацией) по фильтру
auto touristSelected(TouristFilter filter, Navigation nav)
{
	import std.json: JSONValue;
	import std.traits: getUDAs;
	import webtank.common.optional: Optional, isOptional, OptionalValueType;
	import std.conv: text, to;
	import std.meta: AliasSeq, Alias;
	import std.string: join;
	auto dbase = getCommonDB();

	static immutable size_t maxPageSize = 50;
	string[] filters;
	if( nav.limit > maxPageSize ) {
		nav.limit = maxPageSize;
	}

	foreach( fieldName; AliasSeq!(__traits(allMembers, TouristFilter)) )
	{
		alias FieldType = typeof(__traits(getMember, filter, fieldName));
		alias Field = Alias!(__traits(getMember, filter, fieldName));
		static if( is( FieldType == string ) )
		{
			auto field = __traits(getMember, filter, fieldName);
			enum string dbFieldName = getUDAs!(Field, DBName)[0].dbName;
			if( field.length > 0 ) {
				filters ~= dbFieldName ~ ` ilike '%` ~ PGEscapeStr(field) ~ `%'`;
			}
		}
		else static if( isOptional!FieldType && is( OptionalValueType!(FieldType) == int ) )
		{
			auto field = __traits(getMember, filter, fieldName);
			enum string dbFieldName = getUDAs!(Field, DBName)[0].dbName;
			if( field.isSet ) {
				filters ~= dbFieldName ~ ` = ` ~ field.text;
			}
		}
	}

	string query = `select num, family_name, given_name, patronymic, birth_year from tourist `;
	string countQuery = `select count(1) from tourist `;
	if( filters.length > 0 )
	{
		string filtersPart = "where (" ~ filters.join(") and (") ~ ")";
		query ~= filtersPart;
		countQuery ~= filtersPart;
	}
	query ~= ` offset ` ~ nav.offset.text ~ ` limit ` ~ nav.limit.text;

	JSONValue result;
	result[`pageSize`] = nav.limit;
	result[`recordCount`] = getCommonDB().query(countQuery).get(0, 0, "0").to!size_t;
	result[`rs`] = getCommonDB().query(query).getRecordSet(shortTouristRecFormat).toStdJSON();

	return result;
}