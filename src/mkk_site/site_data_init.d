module mkk_site.site_data_init;

import 
	mkk_site.site_config,
	mkk_site.site_data;

///Общие данные для сайта

///Строки подключения к базам данных
//Строка подключения к базе с общими данными
immutable(string) commonDBConnStr;
//Строка подключения к базе с данными аутентификации
immutable(string) authDBConnStr;

///Далее идут пути относительно сайта
immutable(string) publicPath;     //Путь к директории общедоступного статического содержимого
immutable(string) cssPath;  //Путь к директории таблиц стилей
immutable(string) jsPath;   //Путь к директории javascript'ов
immutable(string) imgPath;  //Путь к директории картинок

immutable(string) webtankPublicPath;
immutable(string) webtankCssPath;  //Путь к директории скриптов библиотеки
immutable(string) webtankJsPath;  //Путь к директории стилей библиотеки
immutable(string) webtankImgPath;  //Путь к директории картинок библиотеки

immutable(string) dynamicPath;    //Путь к директории динамического содержимого
immutable(string) restrictedPath; //Путь к директории содержимого с ограниченным доступом
immutable(string) JSON_RPC_Path; //Путь для вызова удалённых процедур


///Пути в файловой системе
immutable(string) siteDir; //Директория сайта

//Пути к ресурсам. Имеются в виду файлы, которые используются сервером
//но не отдаются клиенту непосредственно.
immutable(string) siteResDir; //Ресурсы сайта
immutable(string) webtankResDir; //Ресурсы библиотеки

//Путь к файлу шаблона
immutable(string) pageTemplatesDir;
immutable(string) generalTemplateFileName;
immutable(string) printGeneralTemplateFileName;

///Журналы ошибок и событий (логи)
immutable(string) siteLogsDir;
immutable(string) errorLogFileName; //Путь к журналу ошибок сайта
immutable(string) eventLogFileName; //Путь к журналу событий сайта
immutable(string) webtankErrorLogFileName; //Логи ошибок библиотеки
immutable(string) webtankEventLogFileName; //Логи событий библиотеки
immutable(string) dbQueryLogFileName; //Логи событий библиотеки
immutable(string) prioriteLogFileName; //Путь к журналу приоритетных сообщений

///Ассоциативный массив с путями сайта в файловой системе
immutable(string[string]) siteFileSystemPaths;

///Ассоциативный массив с виртуальными путями сайта (те, что в адресной строке браузера)
immutable(string[string]) siteVirtualPaths;

///Массив со строками подключения к базам данных сервиса
immutable(string[string]) serviceDBConnStrings;
	
shared static this()
{	import std.file, std.json;

	string configFile = readText("mkk_site_config.json");

	auto jsonConfig = parseJSON(configFile);

	assert( jsonConfig.type == JSON_TYPE.OBJECT, `Config root JSON value must be object!!!` );

	assert( "services" in jsonConfig.object, `Config must contain "services" object!!!` );
	JSONValue jsonServices = jsonConfig["services"];
	assert( jsonConfig.type == JSON_TYPE.OBJECT, `Config root JSON value must be object!!!` );

	assert( "applications" in jsonConfig.object, `Config must contain "applications" object!!!` );
	JSONValue jsonApps = jsonConfig["applications"];

	assert( "MKK_site" in jsonApps.object, `Config section "applications" must contain "MKK_site" object!!!` );
	JSONValue jsonMKK_site = jsonApps["MKK_site"];
	assert( jsonMKK_site.type == JSON_TYPE.OBJECT, `Config section "applications.MKK_site" must be object!!!` );

	assert( "fileSystemPaths" in jsonMKK_site.object, `Config section "applications.MKK_site" must contain "fileSystemPaths" object!!!` );
	JSONValue jsonFSPaths = jsonMKK_site["fileSystemPaths"];
	assert( jsonFSPaths.type == JSON_TYPE.OBJECT, `Config section "applications.MKK_site" must be object!!!` );

	assert( "virtualPaths" in jsonMKK_site.object, `Config section "applications.MKK_site" must contain "virtualPaths" object!!!` );
	JSONValue jsonVirtualPaths = jsonMKK_site["virtualPaths"];
	assert( jsonVirtualPaths.type == JSON_TYPE.OBJECT, `Config section "applications.MKK_site.virtualPaths" must be object!!!` );

	//Захардкодим пути в файловой ситеме, используемые по-умолчанию
	string[string] defaultFileSystemPaths = [
		"siteRoot": "~/sites/mkk_site/",
		
		"siteResources": "res/",
		"sitePageTemplates": "res/templates/",
		"siteGeneralTemplateFile": "res/templates/general_template.html",
		
		"siteLogs": "logs/",
		"siteErrorLogFile": "logs/error.log",
		"siteEventLogFile": "logs/event.log",
		"webtankErrorLogFile": "logs/webtank_error.log",
		"webtankEventLogFile": "logs/webtank_event.log",
		"databaseQueryLogFile": "logs/db_query.log",
		"sitePrioriteLogFile": "logs/priorite.log",
		
		"sitePublic": "pub/",
		"siteCSS": "pub/css/",
		"siteJS": "pub/js/",
		"siteImg": "pub/img/",
		
		"webtankResources": "res/webtank/",
		"webtankPublic": "pub/webtank/",
		"webtankCSS": "pub/webtank/css/",
		"webtankJS": "pub/webtank/js/",
		"webtankImg": "pub/webtank/img/"
	];
	
	//Захардкодим адреса сайта, используемые по-умолчанию
	string[string] defaultVirtualPaths = [
		"siteRoot": "/",
		
		"sitePublic": "pub/",
		"siteDynamic": "dyn/",
		"siteRestricted": "restricted/",
		"siteJSON_RPC": "",
		
		"siteLogs": "logs/",
		"siteResources": "res/",
		
		"siteCSS": "pub/css/",
		"siteJS": "pub/js/",
		"siteImg": "pub/img/",
		
		"webtankPublic": "pub/webtank/",
		"webtankCSS": "pub/webtank/css/",
		"webtankJS": "pub/webtank/js/",
		"webtankImg": "pub/webtank/img/"
	];
	
	import std.exception;
	
	auto fsPaths = resolveConfigPaths!(true)(jsonFSPaths, defaultFileSystemPaths, "siteRoot");
	auto virtPaths = resolveConfigPaths!(false)(jsonVirtualPaths, defaultVirtualPaths, "siteRoot");
	
	siteFileSystemPaths = assumeUnique(fsPaths);
	siteVirtualPaths = assumeUnique(virtPaths);
	
	//Задаем часто используемые виртуальные пути
	publicPath = siteVirtualPaths["sitePublic"];
	cssPath = siteVirtualPaths["siteCSS"];
	jsPath = siteVirtualPaths["siteJS"];
	imgPath = siteVirtualPaths["siteImg"];

	webtankPublicPath = siteVirtualPaths["webtankPublic"];
	webtankCssPath = siteVirtualPaths["webtankCSS"];
	webtankJsPath = siteVirtualPaths["webtankJS"];
	webtankImgPath = siteVirtualPaths["webtankImg"];

	dynamicPath = siteVirtualPaths["siteDynamic"];
	restrictedPath = siteVirtualPaths["siteRestricted"];
	JSON_RPC_Path = siteVirtualPaths["siteJSON_RPC"];

	//Задаем часто используемые пути файловой системы
	siteResDir = siteFileSystemPaths["siteResources"]; //Ресурсы сайта
	webtankResDir = siteFileSystemPaths["webtankResources"]; //Ресурсы библиотеки

	pageTemplatesDir = siteFileSystemPaths["sitePageTemplates"];
	generalTemplateFileName = siteFileSystemPaths["siteGeneralTemplateFile"];
	printGeneralTemplateFileName = pageTemplatesDir ~ "print_general_template.html";

	//Пути в файловой системе к файлам журналов
	errorLogFileName = siteFileSystemPaths["siteErrorLogFile"];
	eventLogFileName = siteFileSystemPaths["siteEventLogFile"];
	webtankErrorLogFileName = siteFileSystemPaths["webtankErrorLogFile"];
	webtankEventLogFileName = siteFileSystemPaths["webtankEventLogFile"];
	dbQueryLogFileName = siteFileSystemPaths["databaseQueryLogFile"];
	prioriteLogFileName = siteFileSystemPaths["sitePrioriteLogFile"];
	
	//Вытаскиваем информацию об используемых базах данных
	assert( "MKK" in jsonServices.object, `Config "services" section must contain "MKK" object!!!` );
	JSONValue jsonMKKService = jsonServices["MKK"];
	assert( jsonMKKService.type == JSON_TYPE.OBJECT, `Config section "services.MKK" value must be an object!!!` );
	
	//Вытаскиваем информацию об используемых базах данных
	assert( "databases" in jsonMKKService.object, `Config "services.MKK" section must contain "databases" object!!!` );
	JSONValue jsonDatabases = jsonMKKService["databases"];
	assert( jsonDatabases.type == JSON_TYPE.OBJECT, `Config section "services.MKK.databases" value must be an object!!!` );
	
	//Получаем строки подключения к базам данных
	auto dbConnStrings = resolveConfigDatabases(jsonDatabases);
	serviceDBConnStrings = assumeUnique(dbConnStrings);
	
	commonDBConnStr = serviceDBConnStrings["commonDB"];
	//Строка подключения к базе с данными аутентификации
	authDBConnStr = serviceDBConnStrings["authDB"];

} 
