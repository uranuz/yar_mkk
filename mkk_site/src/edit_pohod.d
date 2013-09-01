module mkk_site.edit_pohod;

import std.stdio, std.conv;

//import webtank.db.database;
import webtank.datctrl.field_type, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.application, webtank.templating.plain_templater;

import mkk_site.site_data;


immutable(string) projectPath = `/webtank`;

Application netApp; //Обявление глобального объекта приложения

///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
}

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	string output; //"Выхлоп" программы
	
	try {
	//Создаём подключение к БД
	string connStr = "dbname=baza_MKK host=192.168.0.72 user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if ( !dbase.isConnected )
		output ~= "Ошибка соединения с БД";
	

	string content = 
	`Код МКК <input type="text" name="kod_mkk" value=""><br>
	Номер маршрутной книги <input type="text" name="nomer_knigi" value=""><br>
	Район путешествия <input type="text" name="region_pohod" value=""><br>
	Организация <input type="text" name="organization" value=""><br>
	Территориальная принадлежность группы <input type="text" name="region_group" value=""><br>
	Вид туризма <input type="text" name="vid" value=""><br>
	Категория трудности <input type="text" name="ks" value=""><br>
	с элементами <input type="text" name="element" value=""><br>
	
	Маршрут <input type="text" name="marchrut" value=""><br>
	Дата начала <input type="text" name="begin_date" value=""><br>
	Дата завершения <input type="text" name="finish_date" value=""><br>
	
	`;
	
	//Чтение шаблона страницы из файла
	import std.stdio;
	auto f = File(generalTemplateFileName, "r");
	string templateStr; //Строка с содержимым файла шаблона страницы 
	string buf;
	while ((buf = f.readln()) !is null)
		templateStr ~= buf;
		
	//Создаем шаблон по файлу
	auto tpl = new PlainTemplater( templateStr );
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне
	//Задаём местоположения всяких файлов
	tpl.set("img folder", "../../mkk_site/img/");
	tpl.set("css folder", "../../mkk_site/css/");
	tpl.set("cgi-bin", "/cgi-bin/mkk_site/");
	tpl.set("useful links", "Куча хороших ссылок");
	tpl.set("js folder", "../../mkk_site/js/");
	
	output ~= tpl.getResult(); //Получаем результат обработки шаблона с выполненными подстановками
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		rp.write(output);
	}
}

