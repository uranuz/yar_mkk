module mkk_site.main_service.document;
import mkk_site.main_service.devkit;
import mkk_site.site_data;
import std.conv, std.string, std.utf;

import std.stdio;

//***********************Обявление метода*******************
shared static this()
{
	Service.JSON_RPCRouter.join!(documentSet)(`document.Set`);

}
//**********************************************************

struct DBName { string dbName; }

struct touristDataToWrite
{
	import webtank.common.optional: Undefable;
	import std.datetime: Date;
	Optional!size_t num; //номер документа

	// Секция "Маршрутная книжка"
	@DBName("name") Undefable!string familyName; // наименование
	@DBName("linr") Undefable!string givenName; // ссылка	
}

import std.typecons: tuple;

/// Формат записи для списка ссылок
static immutable documentRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "Ключ",
	string, "наименование", 
	string,  "ссылка",
	
)();

//--------------------------------------------------------
import std.json;

  JSONValue documentSet
	(
		HTTPContext context,			
		
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

static immutable documentQ =
`select num,name,link
	
from file_link  `;



string documentQuery //запрос содержание таблицы
			=documentQ;

	//writeln(currentPage);
		//writeln(offset.to!string)

		auto documentTabl = getCommonDB()
							.query(documentQuery)
							.getRecordSet(documentRecFormat);

//---------Сборка из всех данных---
		JSONValue DocumentSet;
		  
			DocumentSet["isAuthorized"]  = isAuthorized;
			DocumentSet["DocumentTabl"]  =documentTabl.toStdJSON();
			
		
		  
		return DocumentSet;
	}

struct Navigation
{
	size_t offset = 0;
	size_t limit = 10;
} 



