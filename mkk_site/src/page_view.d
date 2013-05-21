module mkk_site.page_view;

import std.conv;

import webtank.net.application;

webtank.net.application.Application netApp; //Обявление глобального объекта приложения

void netMain(Application netApp)  //Определение главной функции приложения
{	netApp.name = `Тестовое приложение`;
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	immutable(string) thisPagePath = "";
	
	uint pageCount = 10; //Количество страниц
	uint curPageNum = 1; //Номер текущей страницы
	try {
		if( "cur_page_num" in rq.postVars )
			curPageNum = rq.postVars.get("cur_page_num", "1").to!uint;
	} catch (Exception) { curPageNum = 1; }
	string filter = "";  //Фильтр поиска
	if( "filter" in rq.postVars ) 
		filter = rq.postVars.get("filter", "");
		
	string js_file = "../../mkk_site/js/page_view.js";
	
	rp ~= 
`<html><body>
	<form id="main_form" method="post">
		Фильтр: <input name="filter" type="text" value="` ~ filter ~ `">
		<input type="submit" name="act" value="Найти"><br>`;
	
	
	if( (curPageNum > 0) && ( curPageNum <= pageCount ) ) 
	{	if( curPageNum != 1 )
			rp ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum - 1).to!string ~ `)">Предыдущая</a> `;
		
		rp ~= ` Страница <input name="cur_page_num" type="text" value="` ~ curPageNum.to!string ~ `"> из ` 
			~ pageCount.to!string ~ ` <input type="submit" name="act" value="Перейти"> `;
		
		if( curPageNum != pageCount )
			rp ~= ` <a href="#" onClick="gotoPage(` ~ ( curPageNum + 1).to!string ~ `)">Следующая</a> `;
	}
	
	rp ~= 
`	</form>
	<script type="text/javascript" src="` ~ js_file ~ `"></script>
</body></html>`;
}


///Обычная функция main. В ней изменения НЕ ВНОСИМ
int main()
{	//Конструируем объект приложения. Передаём ему нашу "главную" функцию
	netApp = new Application(&netMain); 
	netApp.run(); //Запускаем приложение
	netApp.finalize(); //Завершаем приложение
	return 0;
}

