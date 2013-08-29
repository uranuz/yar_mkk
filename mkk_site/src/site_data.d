module mkk_site.site_data;

///Общие данные для сайта

///Строки подключения к базам данных
//Строка подключения к базе с общими данными
immutable(string) commonDBConnStr = "dbname=baza_MKK host=192.168.0.28 user=postgres password=postgres";
//Строка подключения к базе с данными аутентификации
immutable(string) authDBConnStr = "dbname=postgres host=192.168.0.100 user=postgres password=postgres";

///Пути в файловой системе
//Путь к журналу ошибок сайта
immutable(string) errorLogFileName = "/home/test_serv/sites/test/logs/mkk_site_error.log";
//Путь к журналу событий сайта
immutable(string) eventLogFileName = "/home/test_serv/sites/test/logs/mkk_site_event.log";
//Путь к файлу шаблона
immutable(string) generalTemplateFileName = "/home/test_serv/web_projects/mkk_site/templates/general_template.html";

///Далее идут пути относительно сайта
immutable(string) cssPath = "/css/";  //Путь к директории таблиц стилей
immutable(string) jsPath = "/js/";   //Путь к директории javascript'ов
immutable(string) imgPath = "/img/";  //Путь к директории картинок
immutable(string) publicPath = "/";     //Путь к директории общедоступного статического содержимого
immutable(string) dynamicPath = "/dyn/";    //Путь к директории динамического содержимого
immutable(string) restrictedPath = "/restricted/"; //Путь к директории содержимого с ограниченным доступом