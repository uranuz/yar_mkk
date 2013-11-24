module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.stdio;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.http.routing, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.net.http.context;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "edit_tourist";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
}

void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	auto ticket = context.accessTicket;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	
	bool isAuthorized = 
		ticket.isAuthenticated && 
		( ticket.user.isInGroup("moder") || ticket.user.isInGroup("admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаём подключение к БД		
		string generalTplStr = cast(string) std.file.read( generalTemplateFileName );
		
		//Создаем шаблон по файлу
		auto tpl = getGeneralTemplate(thisPagePath);
		tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ ticket.user.name ~ "</b>!!!</i>");
		tpl.set("user login", ticket.user.login );
	
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
			touristKey = qVars.get("key", null).to!size_t;
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
		{	auto touristRS = dbase.query( "select num, family_name, given_name, patronymic, birth_date, birth_year, address, phone, show_phone, email, show_email, exp, comment, sports_grade, judge_category from tourist where num=" ~ touristKey.to!string ~ ";" ).getRecordSet(touristRecFormat);
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
		if( pVars.get("action", "") == "write" )
			action = ( isTouristKeyAccepted ? ActionType.updateData : ActionType.insertData );
		else
			action = ( isTouristKeyAccepted ? ActionType.showUpdateForm : ActionType.showInsertForm );

		string editTouristFormTplStr = cast(string) std.file.read( pageTemplatesDir ~ "edit_tourist_form.html" );
		
		auto edTourFormTpl = new PlainTemplater( editTouristFormTplStr );
		
		string[] sportsGrades = [ "", "третий", "второй", "первый", "КМС", "МС", "ЗМС" ];
		string[] judgeCategories = [ "", "вторая", "первая", "всероссийская" ];
		

		string[] strFieldNames = [ "family_name", "given_name", "patronymic", "address", "phone", "email", "exp", "comment" ];
		
		string content;
		
		if( action == ActionType.showUpdateForm )
		{	/+edTourFormTpl.set( "num.value", touristRec.get!"ключ"(0).to!string );+/
			edTourFormTpl.set( "family_name", ` value="` ~ HTMLEscapeValue( touristRec.get!"фамилия"("") ) ~ `"` );
			edTourFormTpl.set( "given_name", ` value="` ~ HTMLEscapeValue( touristRec.get!"имя"("") ) ~ `"` );
			edTourFormTpl.set( "patronymic", ` value="` ~ HTMLEscapeValue( touristRec.get!"отчество"("") ) ~ `"` );
 			edTourFormTpl.set( "birth_year", ` value="` ~ touristRec.get!"год рожд"(0).to!string ~ `"` );
 			edTourFormTpl.set( "address", ` value="` ~ HTMLEscapeValue( touristRec.get!"адрес"("") ) ~ `"` );
 			edTourFormTpl.set( "phone", ` value="` ~ HTMLEscapeValue( touristRec.get!"телефон"("") ) ~ `"` );
 			edTourFormTpl.set( "show_phone", ( touristRec.get!"показать телефон"(false) ? " checked" : "" ) );
 			edTourFormTpl.set( "email", ` value="` ~ HTMLEscapeValue( touristRec.get!"эл почта"("") ) ~ `"` );
 			edTourFormTpl.set( "show_email", ( touristRec.get!"показать эл почту"(false) ? " checked" : "" ) );
 			edTourFormTpl.set( "exp", ` value="` ~ HTMLEscapeValue( touristRec.get!"тур опыт"("") ) ~ `"` );
 			edTourFormTpl.set( "comment", HTMLEscapeValue( touristRec.get!"комент"("") ) ); //textarea
 		}
 		
 		if( action == ActionType.showUpdateForm || action == ActionType.showInsertForm )
 		{	import std.string;
			if( action == ActionType.showInsertForm )
			{	string familyName = "'" ~ PGEscapeStr( pVars.get("family_name", "") ) ~ "'";
				string givenName = "'" ~ PGEscapeStr( pVars.get("given_name", "") ) ~ "'";
				string patronymic = "'" ~ PGEscapeStr( pVars.get("given_name", "") ) ~ "'";
				uint birthYear;
				try {	birthYear = pVars.get("given_name", "").to!uint; }
				catch( std.conv.ConvException e ) {  }
				auto touristExistsQRes = 
				dbase.query( `select num, family_name, given_name, patronymic, birth_year from tourist where ` 
				~ PGYotCaseInsensTrimCompare( "family_name", familyName ) 
				~ ` and ` ~ PGYotCaseInsensTrimCompare( "given_name", givenName ) 
				~ ` and ` ~ PGYotCaseInsensTrimCompare( "patronymic", patronymic ) 
				~ ` and birth_year=` ~ birthYear.to!string ~ `;` );
				if( touristExistsQRes.recordCount == 1 )
				{	content = "Турист " ~ touristExistsQRes.get(0, 0) ~ " " ~ touristExistsQRes.get(1, 0) ~ " "
					~ " " ~ touristExistsQRes.get(2, 0) ~ " " ~ touristExistsQRes.get(3, 0) 
					~ " г.р. уже наличествует в базе данных!!!";
					tpl.set( "content", content );
					rp ~= tpl.getString();
				}
			}
			ubyte birthDay;
			ubyte birthMonth;
			if( action == ActionType.showUpdateForm )
			{	auto birthDateParts = split( touristRec.get!"дата рожд"(""), "." );
				if( birthDateParts.length != 2 )
					birthDateParts = split( touristRec.get!"дата рожд"(""), "," );
				if( birthDateParts.length == 2 ) 
				{	import std.conv;
					try
					{	birthDay = birthDateParts[0].to!ubyte;
						birthMonth = birthDateParts[1].to!ubyte;
					}
					catch(std.conv.Exception e)
					{
						
	// 					return;
					}
					
				}
			}
			
			auto birthDayInp = `<select name="birth_day">`;
			birthDayInp ~= `<option value=""` ~ ( ( birthDay == 0 || birthDay > 31 ) ? ` selected` : `` ) ~ `></option>`;
			for( ubyte i = 1; i <= 31; i++ )
			{	birthDayInp ~= `<option value="` ~ i.to!string ~ `"`
				~ ( birthDay == i ? ` selected` : ``) 
				~ `>` ~ i.to!string ~ `</option>`;
			}
			birthDayInp ~= `</select>`;
			edTourFormTpl.set( "birth_day", birthDayInp );
			
			string[] months = [ "январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь" ];
			auto birthMonthInp = `<select name="birth_month">`;
			birthMonthInp ~= `<option value=""` ~ ( ( birthMonth == 0 || birthMonth > 12 ) ? ` selected` : `` ) ~ `></option>`;
			for( ubyte i = 1; i <= 12; i++ )
			{	birthMonthInp ~= `<option value="` ~ i.to!string ~ `"`
				~ ( birthMonth == i ? ` selected` : ``)
				~ `>` ~ months[i-1] ~ `</option>`;
			}
			birthMonthInp ~= `</select>`;
			edTourFormTpl.set( "birth_month", birthMonthInp );
 		
			string sportsGradeInp = `<select name="sports_grade">`;
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
 			edTourFormTpl.set( "action", ` value="write"` );
 			
 			content = edTourFormTpl.getString();
		}
		
		if( action == ActionType.insertData || action == ActionType.updateData )
		{	import std.conv, std.algorithm;
			string queryStr;
			try
			{	string fieldNamesStr;
				string fieldValuesStr;
				
				foreach( i, fieldName; strFieldNames )
				{	string value = pVars.get(fieldName, null);
					if( value.length > 0  )
					{	fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
						fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) ~ "'" ~ PGEscapeStr(value) ~ "'"; 
					}
				}
				
				auto birthDayStr = pVars.get("birth_day", null);
				auto birthMonthStr = pVars.get("birth_month", null);
				if( (birthDayStr.length > 0) && (birthMonthStr.length >0) )
				{	auto birthDay = birthDayStr.to!ubyte;
					auto birthMonth = birthMonthStr.to!ubyte;
					if( birthDay > 0 && birthDay <= 31 && birthMonth > 0 && birthMonth <= 12 )
					{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"birth_date\"";
						fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ birthDay.to!string ~ "." ~ birthMonth.to!string ~ "'";
					}
				}
				
				auto birthYearStr = pVars.get("birth_year", null);
				if( birthYearStr.length > 0 )
				{	auto birthYear = birthYearStr.to!uint;
					fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"birth_year\"";
					fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ birthYear.to!string ~ "'";
				}
				
				bool showPhone = toBool( pVars.get("show_phone", "no") );
				fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"show_phone\"";
				fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ ( showPhone ? "true" : "false" ) ~ "'";

				bool showEmail = toBool( pVars.get("show_email", "no") );
				fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"show_email\"";
				fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ ( showEmail ? "true" : "false" ) ~ "'";

				if( find( sportsGrades, pVars.get("sports_grade", "") ).length > 0  )
				{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"sports_grade\"";
					fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("sports_grade", "") ~ "'";
				}
				else
					throw new std.conv.ConvException("Выражение \"" ~ pVars.get("sports_grade", "") ~ "\" не является значением типа \"спортивный разряд\"!!!");
					
				if( find( judgeCategories, pVars.get("judge_category", "") ).length > 0  )
				{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"judge_category\"";
					fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("judge_category", "") ~ "'";
				}
				else
					throw new std.conv.ConvException("Выражение \"" ~ pVars.get("judge_category", "") ~ "\" не является значением типа \"судейская категория\"!!!");
				
// 				size_t moderKey = postVars.get("moder", "").to!size_t;
// 				~ moderKey.to!string ~ ", "
				if( fieldNamesStr.length > 0 && fieldValuesStr.length > 0 )
				{	if( action == ActionType.insertData )
						queryStr = "insert into tourist ( " ~ fieldNamesStr ~ " ) values( " ~ fieldValuesStr ~ " );";
					else
						queryStr = "update tourist set( " ~ fieldNamesStr ~ " ) = ( " ~ fieldValuesStr ~ " ) where num='" ~ touristKey.to!string ~ "';";
				}
					
			}
			catch(std.conv.ConvException e)
			{	//TODO: Выдавать ошибку
				content = "<h3>Ошибка при разборе данных формы!!!</h3><br>\r\n";
				content ~= e.msg;
				tpl.set( "content", content );
				rp ~= tpl.getString();
				return;
			}
			dbase.query(queryStr);
			if( action == ActionType.insertData )
			{	if( dbase.lastErrorMessage is null )
					content = "<h3>Данные о туристе успешно добавлены в базу данных!!!</h3>"
					~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
				else
					content = "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
					~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
					~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>";
			}
			else
			{	if( dbase.lastErrorMessage is null )
					content = "<h3>Данные о туристе успешно обновлены!!!</h3>"
					~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
				else
					content = "<h3>Произошла ошибка при обновлении данных!!!</h3>"
					~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
					~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
			}
		}
		
		tpl.set( "content", content );
		rp ~= tpl.getString();

	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}

