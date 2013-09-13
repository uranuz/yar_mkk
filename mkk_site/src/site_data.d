module mkk_site.site_data;

///Общие данные для сайта

///Строки подключения к базам данных
//Строка подключения к базе с общими данными
immutable commonDBConnStr = "dbname=baza_MKK host=192.168.0.28 user=postgres password=postgres";
//Строка подключения к базе с данными аутентификации
immutable authDBConnStr = "dbname=postgres host=192.168.0.100 user=postgres password=postgres";

///Пути в файловой системе
//Путь к журналу ошибок сайта
immutable siteDir = "/home/test_serv/sites/test/";
immutable errorLogFileName = siteDir ~ "logs/mkk_site_error.log";
//Путь к журналу событий сайта
immutable eventLogFileName = siteDir ~ "logs/mkk_site_event.log";
//Путь к файлу шаблона
immutable pageTemplatesDir = siteDir ~ "templates/";
immutable generalTemplateFileName = pageTemplatesDir ~ "general_template.html";


///Далее идут пути относительно сайта
immutable cssPath = "/css/";  //Путь к директории таблиц стилей
immutable jsPath = "/js/";   //Путь к директории javascript'ов
immutable imgPath = "/img/";  //Путь к директории картинок
immutable publicPath = "/";     //Путь к директории общедоступного статического содержимого
immutable dynamicPath = "/dyn/";    //Путь к директории динамического содержимого
immutable restrictedPath = "/restricted/"; //Путь к директории содержимого с ограниченным доступом
immutable webtankJsPath = "/webtank/js/"  //Путь к директории скриптов библиотеки