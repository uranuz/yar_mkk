module mkk_site.site_data;

///Перечисление целей сборки сайта
enum BuildTarget {devel, test, release};

//Определение текущей цели сборки сайта
version(devel)
	enum siteBuildTarget = BuildTarget.devel;
else version(test)
	enum siteBuildTarget = BuildTarget.test;
else
	enum siteBuildTarget = BuildTarget.release;


// version(release)
// 	enum isReleaseVersion = true;
// else
// 	enum isReleaseVersion = false;
// 
// version()

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
immutable JSON_RPC_Path = "/jsonrpc/"; //Путь для вызова удалённых процедур


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
immutable(string) prioriteLogFileName; //Путь к журналу приоритетных сообщений

shared static this()
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
	prioriteLogFileName = siteLogsDir ~ "priorite.log";
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
	[	1:"планируется", 2:"набор группы", 3:"набор завершён",
		4:"идёт подготовка", 5:"на маршруте", 6:"пройден", 
		7:"пройден частично",8:"не пройден"
	]);
		
	статусЗаявки = immutable(EnumFormat)(
	[	1:"не заявлен", 2:"подана заявка", 3:"отказ в заявке", 
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
