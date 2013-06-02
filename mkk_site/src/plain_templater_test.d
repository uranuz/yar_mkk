module mkk_site.plain_templater_test;

import std.conv;

import webtank.net.application;
import webtank.templating.plain_templater;

Application netApp; //Обявление глобального объекта приложения

void netMain(Application netApp)  //Определение главной функции приложения
{	netApp.name = `Тестовое приложение`;
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	uint pageCount = 10; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	try {
		if( "cur_page_num" in rq.postVars )
 			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }
	string filter = "";  //Фильтр поиска
	if( "filter" in rq.postVars ) 
		filter = rq.postVars.get("filter", "");
		
	string js_file = "../../js/page_view.js";
	
	string templFileName = "/home/test_serv/sites/test/www/mkk_site/general_template.html";
	import std.stdio;
	auto f = File(templFileName, "r");
	string templateStr;
	string buf;
	while ((buf = f.readln()) !is null)
		templateStr ~= buf;
	
		
	auto tpl = new PlainTemplater( templateStr );
	
	string content_block =
	`<form id="main_form" method="post">
		Фильтр: <input name="filter" type="text" value="` ~ filter ~ `">
		<input type="submit" name="act" value="Найти"><br>`;
	
	
	if( (curPageNum > 0) && ( curPageNum <= pageCount ) ) 
	{	if( curPageNum != 1 )
			content_block ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a> `;
		
		content_block ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~ `"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `;
		
		if( curPageNum != pageCount )
			content_block ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `;
	}
	
	content_block ~= `</form>`;
	
	
	tpl.setContent("content", content_block);
	tpl.setContent("cgi-bin", "/cgi-bin/mkk_site/");
	tpl.setContent("useful links", "Куча хороших ссылок");
	rp ~= tpl.getStr();

}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
}
