module mkk_site.site_data_old;

import 
	mkk_site.config_parsing,
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

///Ассоциативный массив со строками подключения к базам данных сервиса
immutable(string[string]) serviceDBConnStrings;

shared static this()
{
	import std.file: readText;
	import std.json;
	import std.exception: assumeUnique;

	string configFile = readText("mkk_site_config.json");
	auto jsonConfig = parseJSON(configFile);

	string currServiceName = "yarMKKMain";
	auto jsonCurrService = getServiceConfig(jsonConfig, currServiceName);
	auto fsPaths = getServiceFileSystemPaths(jsonCurrService);
	auto virtPaths = getServiceVirtualPaths(jsonCurrService);
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

	//Получаем строки подключения к базам данных
	auto dbConnStrings = getServiceDatabases(jsonCurrService);
	serviceDBConnStrings = assumeUnique(dbConnStrings);
	
	commonDBConnStr = serviceDBConnStrings["commonDB"];
	//Строка подключения к базе с данными аутентификации
	authDBConnStr = serviceDBConnStrings["authDB"];

} 
