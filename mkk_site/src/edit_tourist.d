module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.stdio;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.application, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

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
	{	//Пользователь авторизован делать бесчинства
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
		
		//Пытаемся получить ключ
		bool isTouristKeyAccepted = false;
		
		size_t touristKey;
		try {
			touristKey = rq.queryVars.get("key", null).to!size_t;
			isTouristKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isTouristKeyAccepted = false; }
		
		alias FieldType ft;
		auto touristRecFormat = RecordFormat!(
			ft.IntKey, "ключ", ft.Str, "фамилия", ft.Str, "имя", ft.Str, "отчество",
			ft.Str, "дата рожд", ft.Int, "год рожд", ft.Str, "адрес", ft.Str, "телефон",
			ft.Bool, "показать телефон", ft.Str, "эл почта", ft.Bool, "показать эл почту",
			ft.Str, "тур опыт", ft.Str, "комент", ft.Str, "спорт разряд",
			ft.Str, "суд категория"
		)();
		
		Record!( typeof(touristRecFormat) ) touristRec;
		
		//Если в принципе ключ является числом, то получаем данные из БД
		if( isTouristKeyAccepted )
		{	auto touristRS = dbase.query( "select * from tourist where num=" ~ touristKey.to!string ~ ";" ).getRecordSet(touristRecFormat);
			if( ( touristRS !is null ) && ( touristRS.length == 1 ) ) //Если получили одну запись -> ключ верный
			{	touristRec = touristRS.front;
				isTouristKeyAccepted = true;
			}
			else
				isTouristKeyAccepted = false;
		}
		
		//Перечислимый тип, который определяет выполняемое действие
		enum ActionType { showInsertForm, showUpdateForm, insertData, updateData };
		
		ActionType action;
		//Определяем выполняемое страницей действие
		if( rq.postVars.get("action", "") == "write" )
			action = ( isTouristKeyAccepted ? ActionType.updateData : ActionType.insertData );
		else
			action = ( isTouristKeyAccepted ? ActionType.showUpdateForm : ActionType.showInsertForm );

		string editTouristFormTplStr = cast(string) std.file.read( pageTemplatesDir ~ "edit_tourist_form.html" );
		
		auto edTourFormTpl = new PlainTemplater( editTouristFormTplStr );
		
		string[] sportsGrades = [ "", "третий", "второй", "первый", "КМС", "МС", "ЗМС" ];
		string[] judgeCategories = [ "", "вторая", "первая", "всероссийская" ];
		

		
		if( action == ActionType.showUpdateForm )
		{	/+edTourFormTpl.set( "num.value", touristRec.get!"ключ"(0).to!string );+/
			edTourFormTpl.set( "family_name", ` value="` ~ HTMLEscapeValue( touristRec.get!"фамилия"("") ) ~ `"` );
			edTourFormTpl.set( "given_name", ` value="` ~ HTMLEscapeValue( touristRec.get!"имя"("") ) ~ `"` );
			edTourFormTpl.set( "patronymic", ` value="` ~ HTMLEscapeValue( touristRec.get!"отчество"("") ) ~ `"` );
 			edTourFormTpl.set( "birth_year", ` value="` ~ touristRec.get!"год рожд"(0).to!string ~ `"` );
 			edTourFormTpl.set( "address", ` value="` ~ HTMLEscapeValue( touristRec.get!"адрес"("") ) ~ `"` );
 			edTourFormTpl.set( "phone", ` value="` ~ HTMLEscapeValue( touristRec.get!"телефон"("") ) ~ `"` );
 			edTourFormTpl.set( "show_phone", ( touristRec.get!"показать телефон"(false) ? " checked" : "" ) );
 			edTourFormTpl.set( "email.value", ` value="` ~ HTMLEscapeValue( touristRec.get!"эл почта"("") ) ~ `"` );
 			edTourFormTpl.set( "show_email", ( touristRec.get!"показать эл почту"(false) ? " checked" : "" ) );
 			edTourFormTpl.set( "exp", ` value="` ~ HTMLEscapeValue( touristRec.get!"тур опыт"("") ) ~ `"` );
 			edTourFormTpl.set( "comment", ` value="` ~ HTMLEscapeValue( touristRec.get!"комент"("") ) ~ `"` );
 		}
 		
 		if( action == ActionType.showUpdateForm || action == ActionType.showInsertForm )
 		{	string sportsGradeInp = `<select name="sports_grade">`;
 			foreach( grade; sportsGrades )
 			{	sportsGradeInp ~= `<option value="` ~ grade ~ `"`;
				if( action == ActionType.showUpdateForm )
					sportsGradeInp ~= ( (touristRec.get!"спорт разряд"("") == grade) ? " selected" : "" );
				sportsGradeInp ~= `>` ~ grade ~ `</option>`;
 			}
 			sportsGradeInp ~= `</select>`;
 			edTourFormTpl.set( "sports_grade", sportsGradeInp );
 			
 			string judgeCategoryInp = `<select name="judge_category">`;
 			foreach( category; judgeCategories )
 			{	judgeCategoryInp ~= `<option value="` ~ category ~ `"`;
				if( action == ActionType.showUpdateForm )
					judgeCategoryInp ~= ( (touristRec.get!"суд категория"("") == category) ? " selected" : "" );
				judgeCategoryInp ~= `>` ~ category ~ `</option>`;
			}
 			judgeCategoryInp ~= `</select>`;
 			edTourFormTpl.set( "judge_category", judgeCategoryInp );
		}
		
		if( action == ActionType.insertData )
		{	/+dbase.query("insert into tourist ( family_name, given_name, patronymic, birth_date, birth_year, address, phone, show_phone, email, show_email, exp, comment, sports_grade, judge_category, moder ) values( "
			~ pgEscapeStr( postVars.get("family_name", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("given_name", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("patronymic", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("birth_date", "") ) ~ ", "
			~ postVars.get("birth_year", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("address", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("phone", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("show_phone", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("email", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("show_email", "") ) ~ ", "
			~ pgEscapeStr( postVars.get("show_email", "") ) ~ ", "
			~" )")+/
			
		}
		
		if( action == ActionType.updateData )
		{	
			
		}
		
		string content = edTourFormTpl.getString();

		
		tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ auth.userInfo.name ~ "</b>!!!</i>");
		tpl.set( "user login", auth.userInfo.login );
		tpl.set( "content", content );
		rp ~= tpl.getString();
		
		
	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}

