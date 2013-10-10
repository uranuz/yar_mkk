module mkk_site.site_data;

///Общие данные для сайта

///Строки подключения к базам данных
//Строка подключения к базе с общими данными
immutable commonDBConnStr = "dbname=baza_MKK host=127.0.0.1 user=postgres password=postgres";
//Строка подключения к базе с данными аутентификации
immutable authDBConnStr = "dbname=MKK_site_base host=127.0.0.1 user=postgres password=postgres";

///Пути в файловой системе
//Пути к директориям сайта в файловой системе
immutable siteDir = "$HOME/sites/mkk_site/";  //Директория сайта

//Пути к ресурсам. Имеются в виду файлы, которые используются сервером
//но не отдаются клиенту непосредственно.
immutable siteResDir = siteDir ~ "res/"; //Ресурсы сайта
immutable webtankResDir = resourcesDir ~ "webtank/"; //Ресурсы библиотеки

//Путь к файлу шаблона
immutable pageTemplatesDir = siteResDir ~ "templates/";
immutable generalTemplateFileName = pageTemplatesDir ~ "general_template.html";

///Журналы ошибок и событий (логи)
immutable siteLogsDir = siteDir ~ "logs/"
immutable errorLogFileName = siteLogsDir ~ "error.log"; //Путь к журналу ошибок сайта
immutable eventLogFileName = siteLogsDir ~ "event.log"; //Путь к журналу событий сайта
immutable webtankErrorLogFileName = siteLogsDir ~ "webtank_error.log"; //Логи ошибок библиотеки
immutable webtankEventLogFileName = siteLogsDir ~ "webtank_event.log"; //Логи событий библиотеки
immutable dbQueryLogFileName = siteLogsDir ~ "db_query.log"; //Логи событий библиотеки

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
