module mkk_site.site_data;

///Общие данные для сайта

///Строки подключения к базам данных
//Строка подключения к базе с общими данными
immutable commonDBConnStr = "dbname=baza_MKK host=127.0.0.1 user=postgres password=postgres";
//Строка подключения к базе с данными аутентификации
immutable authDBConnStr = "dbname=MKK_site_base host=127.0.0.1 user=postgres password=postgres";

///Далее идут пути относительно сайта
immutable publicPath = "/pub/";     //Путь к директории общедоступного статического содержимого
immutable cssPath = publicPath ~ "css/";  //Путь к директории таблиц стилей
immutable jsPath = publicPath ~ "js/";   //Путь к директории javascript'ов
immutable imgPath = publicPath ~ "img/";  //Путь к директории картинок

immutable webtankPublicPath = publicPath ~ "webtank/";
immutable webtankCssPath = webtankPublicPath ~ "css/";  //Путь к директории скриптов библиотеки
immutable webtankJsPath = webtankPublicPath ~ "js/";  //Путь к директории стилей библиотеки
immutable webtankImgPath = webtankPublicPath ~ "img/";  //Путь к директории картинок библиотеки

immutable dynamicPath = "/dyn/";    //Путь к директории динамического содержимого
immutable restrictedPath = "/restricted/"; //Путь к директории содержимого с ограниченным доступом


///Пути в файловой системе
//Пути к директориям сайта в файловой системе
private immutable _siteDir = "~/sites/mkk_site/"; //Директория сайта относительно $HOME с тильдой

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

static this()
{	import std.path;
	siteDir = std.path.expandTilde(_siteDir); //Расчёт директории сайта

	siteResDir = siteDir ~ "res/"; //Ресурсы сайта
	webtankResDir = siteResDir ~ "webtank/"; //Ресурсы библиотеки

	pageTemplatesDir = siteResDir ~ "templates/";
	generalTemplateFileName = pageTemplatesDir ~ "general_template.html";

	siteLogsDir = siteDir ~ "logs/";
	errorLogFileName = siteLogsDir ~ "error.log";
	eventLogFileName = siteLogsDir ~ "event.log";
	webtankErrorLogFileName = siteLogsDir ~ "webtank_error.log";
	webtankEventLogFileName = siteLogsDir ~ "webtank_event.log";
	dbQueryLogFileName = siteLogsDir ~ "db_query.log";
}

// перечислимые значения(типы) в таблице данных (в форме ассоциативных массивов)
enum string[int] видТуризма=[0:"", 1:"пешеходный", 2:"лыжный", 3:"горный", 4:"водный", 5:"велосипедный",
		6: "автомото", 7:"спелео", 8:"парусный", 9:"конный", 10:"комбинированный" ];


