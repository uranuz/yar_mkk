module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.stdio;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.application, webtank.templating.plain_templater;

import mkk_site.site_data, mkk_site.authentication;

immutable thisPagePath = dynamicPath ~ "edit_tourist";
immutable authPagePath = dynamicPath ~ "auth";

static this()
{	Application.setHandler(&netMain, thisPagePath );
	Application.setHandler(&netMain, thisPagePath ~ "/");
}

void netMain(Application netApp)  //Определение главной функции приложения
{	
	auto rp = netApp.response;
	auto rq = netApp.request;
	
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );
	
	if( auth.isIdentified() && ( (auth.userInfo.group == "moder") || (auth.userInfo.group == "admin") )  )
	{	//Ползователь авторизован делать бесчинства
		//Создаём подключение к БД		
		string generalTplStr = cast(string) std.file.read( generalTemplateFileName );
		
		//Создаем шаблон по файлу
		auto tpl = new PlainTemplater( generalTplStr );
// 		tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне
		//Задаём местоположения всяких файлов
		tpl.set("img folder", imgPath);
		tpl.set("css folder", cssPath);
		tpl.set("dynamic path", dynamicPath);
		tpl.set("useful links", "Куча хороших ссылок");
		tpl.set("js folder", jsPath);
		tpl.set("this page path", thisPagePath);
	
		auto dbase = new DBPostgreSQL(commonDBConnStr);
		if ( !dbase.isConnected )
		{	tpl.set( "content", "<h3>База данных МКК не доступна!</h3>" );
			rp ~= tpl.getString();
			return; //Завершаем
		}
		
		bool isEditMode = false;
		bool isTouristKeyAcepted = false;
		
		size_t touristKey;
		try {
			touristKey = rq.queryVars.get("tourist_key", null).to!size_t;
			isTouristKeyAcepted = true;
		}
		catch(Exception e)
		{	isTouristKeyAcepted = false; }
		
		alias FieldType ft;
		auto touristRecFormat = RecordFormat!(
			ft.IntKey, "ключ", ft.Str, "фамилия", ft.Str, "имя", ft.Str, "отчество",
			ft.Str, "дата рожд", ft.Int, "год рожд", ft.Str, "адрес", ft.Str, "телефон",
			ft.Bool, "показать телефон", ft.Str, "эл почта", ft.Bool, "показать эл почту",
			ft.Str, "тур опыт", ft.Str, "комент", ft.Str, "спорт разряд",
			ft.Str, "суд категория"
		)();
		
		
		
		RecordSet!( typeof(touristRecFormat) ) touristRS;
		if( isTouristKeyAcepted )
		{	touristRS = dbase.query( "select * from tourist where num=" ~ touristKey.to!string ~ ";" ).getRecordSet(touristRecFormat);
			isEditMode = ( touristRS.length == 1 ) ;
		}
		

		string editTouristFormTplStr = cast(string) std.file.read( pageTemplatesDir ~ "edit_tourist_form.html" );
		
		auto edTourFormTpl = new PlainTemplater( editTouristFormTplStr );
		
		string[] sportsGrades = [ "", "третий", "второй", "первый", "КМС", "МС", "ЗМС" ];
		string[] judgeCategories = [ "", "вторая", "первая", "всероссийская" ];
		
		auto touristRec = touristRS.front;
		
		
		
		if( isEditMode && (touristRS !is null) )
		{	/+edTourFormTpl.set( "num.value", touristRec.get!"ключ"(0).to!string );+/
			edTourFormTpl.set( "family_name.value", touristRec.get!"фамилия"("") );
			edTourFormTpl.set( "given_name.value", touristRec.get!"имя"("") );
			edTourFormTpl.set( "patronymic.value", touristRec.get!"отчество"("") );
 			edTourFormTpl.set( "birth_year.value", touristRec.get!"год рожд"(0).to!string );
 			edTourFormTpl.set( "address.value", touristRec.get!"адрес"("") );
 			edTourFormTpl.set( "phone.value", touristRec.get!"телефон"("") );
 			edTourFormTpl.set( "show_phone.flag", ( touristRec.get!"показать телефон"(false) ? " checked" : "" ) );
 			edTourFormTpl.set( "email.value", touristRec.get!"эл почта"("") );
 			edTourFormTpl.set( "show_email.flag", ( touristRec.get!"показать эл почту"(false) ? " checked" : "" ) );
 			edTourFormTpl.set( "exp.value", touristRec.get!"тур опыт"("") );
 			edTourFormTpl.set( "comment.value", touristRec.get!"комент"("") );
 			string sportsGradeInp = `<select name="sports_grade">`;
 			foreach( grade; sportsGrades )
 				sportsGradeInp ~= `<option value="` ~ grade ~ `"` ~ ( (touristRec.get!"спорт разряд"("") == grade) ? " selected" : "" ) ~ `>` ~ grade ~ `</option>`;
 			sportsGradeInp ~= `</select>`;
 			edTourFormTpl.set( "sports_grade", sportsGradeInp );
 			
 			import std.string;
 			string judgeCategoryInp = `<select name="judge_category">`;
 			foreach( category; judgeCategories )
 				judgeCategoryInp ~= `<option value="` ~ category ~ `"` ~ ( ( strip(touristRec.get!"суд категория"("")) == category ) ? " selected" : "" ) ~ `>` ~ category ~ `</option>`;
 			judgeCategoryInp ~= `</select>`;
 			edTourFormTpl.set( "judge_category", judgeCategoryInp );
		}
		else
		{	
			
		}
		
// 		edTourFormTpl.set(  );
		
		string content = edTourFormTpl.getString();

		
		tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ auth.userInfo.name ~ "</b>!!!</i>");
		tpl.set( "user login", auth.userInfo.login );
		tpl.set( "content", content );
		rp ~= tpl.getString();
		
		
// 		///Начинаем оформлять таблицу с данными
// 		auto touristRecFormat = RecordFormat!(
// 		ft.IntKey, "Ключ",   ft.Str, "Имя", ft.Str, "Дата рожд", 
// 		ft.Str,  "Опыт",   ft.Str, "Контакты",  ft.Str, "Комментарий")();
// 		
// 		
// 				
// 		auto response = dbase.query(queryStr); //запрос к БД
// 		auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
// 		
// 		foreach(rec; rs)
// 		{	
// 		}

	
	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}

