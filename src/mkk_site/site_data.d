module mkk_site.site_data;

import mkk_site.site_config;

///Перечисление целей сборки сайта
enum BuildTarget {	release, test, devel};

///Определение текущей цели сборки сайта
///Разрешена только одна из версий (по умолчанию версия release)
version(devel)
	enum MKKSiteBuildTarget = BuildTarget.devel;
else version(test)
	enum MKKSiteBuildTarget = BuildTarget.test;
else
	enum MKKSiteBuildTarget = BuildTarget.release;


///Константы для определения типа сборки сайта ИКК
enum bool isMKKSiteReleaseTarget = MKKSiteBuildTarget == BuildTarget.release;
enum bool isMKKSiteTestTarget = MKKSiteBuildTarget == BuildTarget.test;
enum bool isMKKSiteDevelTarget = MKKSiteBuildTarget == BuildTarget.devel;

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
	
	import std.stdio;
	writeln(serviceDBConnStrings);
}

// перечислимые значения(типы) в таблице данных (в форме ассоциативных массивов)
import webtank.datctrl.record_format;

immutable(EnumFormat) месяцы;

immutable(EnumFormat) видТуризма;
immutable(EnumFormat) категорияСложности;
immutable(EnumFormat) элементыКС;
immutable(EnumFormat) готовностьПохода;
immutable(EnumFormat) статусЗаявки;
immutable(EnumFormat) спортивныйРазряд;
immutable(EnumFormat) судейскаяКатегория;


shared static this()
{
	месяцы = immutable(EnumFormat)(
	[	1:"январь", 2:"февраль", 3:"март", 4:"апрель", 5:"май", 
		6:"июнь", 7:"июль", 8:"август", 9:"сентябрь", 
		10:"октябрь", 11:"ноябрь", 12:"декабрь" 
	]);
	
	//походы
	видТуризма = immutable(EnumFormat)(
	[	1:"пешеходный", 2:"лыжный", 3:"горный", 4:"водный", 
		5:"велосипедный", 6:"автомото", 7:"спелео", 8:"парусный",
		9:"конный", 10:"комбинированный" 
	]);
	
	// виды туризма
	категорияСложности = immutable(EnumFormat)(
	[	0:"н.к.", 1:"первая", 2:"вторая", 3:"третья", 
		4:"четвёртая",5:"пятая",6:"шестая",
		7:"путешествие", 8:"любая", 9:"ПВД"
	]);
	
	// категории сложности
	элементыКС = immutable(EnumFormat)(
	[	1:"с эл.1", 2:"с эл.2", 3:"с эл.3", 
		4:"с эл.4",5:"с эл.5",6:"с эл.6"
	]);
		
	готовностьПохода = immutable(EnumFormat)(
	[0:"не известна", 	1:"планируется", 2:"набор группы", 3:"набор завершён",
		4:"идёт подготовка", 5:"на маршруте", 6:"пройден", 
		7:"пройден частично",8:"не пройден"
	]);
		
	статусЗаявки = immutable(EnumFormat)(
	[	0:"не определён", 1:"не заявлен", 2:"подана заявка", 3:"отказ в заявке", 
		4:"заявлен", 5:"засчитан", 6:"засчитан частично", 7:"не засчитан"
	]);
		

	// туристы
	спортивныйРазряд = immutable(EnumFormat)(
	[	900:"без разряда",
		603:"третий юн.", 602:"второй юн.", 601:"первый юн.",
		403:"третий", 402:"второй", 401:"первый",
		400:"КМС",
		205:"МС", 204:"ЗМС", 203:"МСМК",
		202:"МСМК и ЗМС"
	], false /*Сортировка по убыванию*/);
	 
	судейскаяКатегория = immutable(EnumFormat)(
	[	900:"без категории", 402:"вторая", 401:"первая", 
		202:"всероссийская", 201:"всесоюзная",101:"международная"
	], false);
}
