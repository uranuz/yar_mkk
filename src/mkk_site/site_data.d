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

// перечислимые значения(типы) в таблице данных (в форме ассоциативных массивов)
import webtank.datctrl.enum_format;

import std.typecons;

alias t = tuple;

static immutable месяцы = enumFormat( 
	[	t(1,"январь"), t(2,"февраль"), t(3,"март"), t(4,"апрель"), t(5,"май"), 
		t(6,"июнь"), t(7,"июль"), t(8,"август"), t(9,"сентябрь"), 
		t(10,"октябрь"), t(11,"ноябрь"), t(12,"декабрь")
	]);
	
	
static immutable месяцы_родительный = enumFormat( 
	[	t(1,"января"), t(2,"февраля"), t(3,"марта"), t(4,"апреля"), t(5,"майя"), 
		t(6,"июня"), t(7,"июля"), t(8,"августа"), t(9,"сентября"), 
		t(10,"октября"), t(11,"ноября"), t(12,"декабря")
	]);	

static immutable видТуризма = enumFormat(
	[	t(1,"пешеходный"), t(2,"лыжный"), t(3,"горный"), t(4,"водный"), 
		t(5,"велосипедный"), t(6,"автомото"), t(7,"спелео"), t(8,"парусный"),
		t(9,"конный"), t(10,"комбинированный") 
	]);
	
static immutable категорияСложности = enumFormat(
	[	t(0,"н.к."), t(1,"первая"), t(2,"вторая"), t(3,"третья"), 
		t(4,"четвёртая"), t(5,"пятая"), t(6,"шестая"),
		t(7,"путешествие"), t(9,"ПВД")
	]);
static immutable элементыКС = enumFormat(
	[	t(1,"с эл. 1"), t(2,"с эл. 2"), t(3,"с эл. 3"), 
		t(4,"с эл. 4"), t(5,"с эл. 5"), t(6,"с эл. 6")
	]);
static immutable готовностьПохода = enumFormat(
	[	t(1,"планируется"), t(2,"набор группы"), t(3,"набор завершён"),
		t(4,"идёт подготовка"), t(5,"на маршруте"), t(6,"пройден"), 
		t(7,"пройден частично"), t(8,"не пройден")
	]);
static immutable статусЗаявки = enumFormat(
	[	t(1,"не заявлен"), t(2,"подана заявка"), t(3,"отказ в заявке"), 
		t(4,"заявлен"), t(5,"засчитан"), t(6,"засчитан частично"), t(7,"не засчитан")
	]);
static immutable спортивныйРазряд = enumFormat(
	[	t(900,"без разряда"),
		t(603,"третий юн."), t(602,"второй юн."), t(601,"первый юн."),
		t(403,"третий"), t(402,"второй"), t(401,"первый"),
		t(400,"КМС"),
		t(205,"МС"), t(204,"ЗМС"), t(203,"МСМК"),
		t(202,"МСМК и ЗМС")
	]);
static immutable судейскаяКатегория = enumFormat(
	[	t(900,"без категории"), t(402,"вторая"), t(401,"первая"), 
		t(202,"всероссийская"), t(201,"всесоюзная"), t(101,"международная")
	]);
