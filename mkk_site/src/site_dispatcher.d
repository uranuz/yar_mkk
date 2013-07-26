module mkk_site.site_dispatcher;

import webtank.net.application;

//Импортируем модули, в которых лежат обработчики страниц
import mkk_site.show_tourist, mkk_site.show_pohod, mkk_site.show_modr,
mkk_site.edit_tourist, mkk_site.edit_pohod;

//Список динамических страниц:
// - Туристы: просмотр  - show_tourist
// - Туристы: редактирование - edit_tourist
// - Поход: просмотр - show_pohod
// - Поход: редактирование - edit_pohod
// - Модератор: просмотр show_modr

//Параметры для инициализации страницы
// - Строка подключения к БД
// - Пути к файлам логов на сервере
// - Пути к другим страницам и ресурсам


class SiteDispatcher
{	
	//Строки подключения к базам данных
	immutable(string) commonDBConnStr = "";  //Строка подключения к базе с общими данными
	immutable(string) authDBConnStr = "";  //Строка подключения к базе с данными аутентификации
	
	//Пути к журналам в файловой системе
	immutable(string) errorLogFileName = "/home/test_serv/sites/test/logs/mkk_site_error.log"; //Путь к журналу ошибок сайта
	immutable(string) eventLogFileName = "/home/test_serv/sites/test/logs/mkk_site_event.log"; //Путь к журналу событий сайта
	
	//Далее идут пути относительно сайта
	immutable(string) cssPath = "/css/";  //Путь к директории таблиц стилей
	immutable(string) jsPath = "/js/";   //Путь к директории javascript'ов
	immutable(string) imgPath = "/img/";  //Путь к директории картинок
	immutable(string) publicPath = "/pub/";     //Путь к директории общедоступного статического содержимого
	immutable(string) dynamicPath = "/dyn/";    //Путь к директории динамического содержимого
	immutable(string) restrictedPath = "/restricted/"; //Путь к директории содержимого с ограниченным доступом
	
	alias void function(webtank.net.application.Application netApp) appHandlerType;
	
	immutable(appHandlerType[string]) appHandlers;
	
	static this()
	{	appHandlers ~= 
		
		
	}
	
	void execute()
	{	
		
		
		
	}
	
	
	
	
}