module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.stdio, std.utf;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.http.routing, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.net.http.context;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;
import std.conv, std.algorithm;

immutable thisPagePath = dynamicPath ~ "edit_tourist";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
}

void netMain(HTTPContext context)
{	
   int числоСовпадений;
   string table;
	auto rq = context.request;
	auto rp = context.response;
	auto ticket = context.accessTicket;
	
	auto pVars = context.request.postVars;
	auto qVars = context.request.queryVars;
	
	if( ticket.isAuthenticated && ( ticket.user.isInGroup("moder") || ticket.user.isInGroup("admin") )  )
	{	//Пользователь авторизован делать бесчинства
		//Создаём подключение к БД		
		
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
			touristKey = qVars.get("key", null).to!size_t;//принимается ключ (и преобразуется в номер туриста)
			isTouristKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isTouristKeyAccepted = false; }
		
		alias FieldType ft;
		auto touristRecFormat = RecordFormat!(
			ft.IntKey, "ключ", ft.Str, "фамилия", ft.Str, "имя", ft.Str, "отчество",
			ft.Str, "дата рожд", ft.Int, "год рожд", ft.Str, "адрес", ft.Str, "телефон",
			ft.Bool, "показать телефон", ft.Str, "эл почта", ft.Bool, "показать эл почту",
			ft.Str, "тур опыт", ft.Str, "комент", ft.Int, "спорт разряд",
			ft.Int, "суд категория"
		)();
		
		Record!( typeof(touristRecFormat) ) touristRec;
		
		//Если в принципе ключ является числом, то получаем данные из БД
		if( isTouristKeyAccepted )
		{	auto touristRS = dbase.query( "select num, family_name, given_name, patronymic, birth_date, birth_year, address, phone, show_phone, email, show_email, exp, comment, razr, sud from tourist where num=" ~ touristKey.to!string ~ ";" ).getRecordSet(touristRecFormat);
			if( ( touristRS !is null ) && ( touristRS.length == 1 ) ) //Если получили одну запись -> ключ верный
			{	touristRec = touristRS.front;
				isTouristKeyAccepted = true;
			}
			else
				isTouristKeyAccepted = false;
		}
		
		//Перечислимый тип, который определяет выполняемое действие
		enum ActionType { 
			showInsertForm, //Показать форму вставки нового туриста
			showUpdateForm, //Показать форму изменения туриста
			insertData, //Приём данных и вставка нового туриста в БД
			updateData //Приём данных и обновление информации о существующем туристе в БД
		};
		
		ActionType action;
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
			action = ( isTouristKeyAccepted ? ActionType.updateData : ActionType.insertData );
		else
			action = ( isTouristKeyAccepted ? ActionType.showUpdateForm : ActionType.showInsertForm );

		string editTouristFormTplStr = cast(string) std.file.read( pageTemplatesDir ~ "edit_tourist_form.html" );
		
		auto edTourFormTpl = new PlainTemplater( editTouristFormTplStr );
		
		
		
		
		
		
		//string[] sportsGrades = ["", "третий","второй", "первый", "КМС","МС","ЗМС","МСМК"];
		
		//string[] judgeCategories = [ "", "вторая", "первая", "всероссийская" ];
		

		string[] strFieldNames = [ "family_name", "given_name", "patronymic", "address", "phone", "email", "exp", "comment" ];
		
		
		string content;
		
		//Вывод данных о туристе в форму редакирования
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
 		//-----------------------------------------------------------------------------------
 		
 		// показ формы для обновления или вставки
 		if( action == ActionType.showUpdateForm || action == ActionType.showInsertForm )
 		{	import std.string;
						
			ubyte birthDay;
			ubyte birthMonth;
			//Вывод даты рождения туриста из базы данных
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
			//Формируем окошечки вывода даты
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
			
			
			
			//Окошечко вывода разряда туриста
		
 			
 			string sportsGradeInp = 
			`<select name="sports_grade">`;
			import std.algorithm;
			int[] ключиСпортРазрядов = спортивныйРазряд.keys;
			sort!("a > b")(ключиСпортРазрядов);
			
 			foreach( i; ключиСпортРазрядов ) 			
 			{	sportsGradeInp ~= `<option value="` ~ i.to!string ~ `"`;
				if( action == ActionType.showUpdateForm )
					sportsGradeInp ~= ( (touristRec.get!"спорт разряд"(1000) == i) ? " selected" : "" );
				sportsGradeInp ~= `>` ~ спортивныйРазряд[i] ~ `</option>`;
 			}
 			sportsGradeInp ~= `</select>`;
 			edTourFormTpl.set( "sports_grade", sportsGradeInp );
 			
 			
 			//Окошечко вывода судейской категории туриста
 			string judgeCategoryInp = `<select name="judge_category">`;
 			int[] ключиСудеКатегорий = судейскаяКатегория.keys;
 			sort!("a > b")(ключиСудеКатегорий);
 			
 			foreach( i; ключиСудеКатегорий )
 			{	judgeCategoryInp ~= `<option value="` ~ i.to!string ~ `"`;
				if( action == ActionType.showUpdateForm )
					judgeCategoryInp ~= ( (touristRec.get!"суд категория"(1000) == i) ? " selected" : "" );
				judgeCategoryInp ~= `>` ~ судейскаяКатегория[i] ~ `</option>`;
			}
 			judgeCategoryInp ~= `</select>`;
 			edTourFormTpl.set( "judge_category", judgeCategoryInp );
 			edTourFormTpl.set( "action", ` value="write"` );
 			
 			content = edTourFormTpl.getString();
		}
		
		
		// конец показ формы для обновления или вставки
		//-------------------------------------------------------------------
		
		//Собственно проверка и запись данных в БД
		if( action == ActionType.insertData || action == ActionType.updateData )
		{	
			import std.string;
			if( action == ActionType.insertData )
			{	string familyName =  PGEscapeStr( pVars.get("family_name", "") );
				string givenName  =  PGEscapeStr( pVars.get("given_name", "") );
				string patronymic =  PGEscapeStr( pVars.get("given_name", "") );
				
			
				uint birthYear;
				try {	birthYear = pVars.get("given_name", "").to!uint; }
				catch( std.conv.ConvException e ) {  }
				
				
		auto короткийФорматТурист = RecordFormat!(
			ft.IntKey, "ключ", ft.Str, "фамилия", ft.Str, "имя", ft.Str, "отчество",
			 ft.Int, "год рожд"
		)();
		
		
		
				
				//: Проверить количество совпадений  в базе
			//	string select_str1 =`select count(1) from tourist`;
				
				
				
				string  fff;//запрос на наличие туриста в базе
				try {
				
				fff=`select num, family_name, given_name, patronymic, birth_year from tourist where ` 
				~ `family_name=         '`~ familyName ~`' ` 
				~ ` and (`;
				
				if(givenName.length!=0)
				{fff~= ` given_name ILIKE   '`~givenName[0..givenName.toUTFindex(1)]~`%' 
				                OR  coalesce(given_name, '') = ''	) `;}
				  else   { fff~=  ` given_name ILIKE  '%%' OR  coalesce(given_name, '') = ''	 )` ;  }           
				fff~=  ` and (`;
				 
				if(patronymic.length!=0) 
				{fff~= ` patronymic  ILIKE  '`~patronymic[0..patronymic.toUTFindex(1)]~`%' 
				                       OR     coalesce(patronymic, '') = '') `;}
				      else   { fff~=  ` patronymic ILIKE  '%%'  OR     coalesce(patronymic, '') = '' )` ;  }                                    
				 
				 if(birthYear.to!string =0) 
				 { fff~=  ` birth_year IS NULL` ;  }  
				
				   else   {fff~= ` and (birth_year=    '`~ birthYear.to!string 
				                                       ~ `' OR  birth_year IS NULL);` ;}                                      
				}
				catch(Throwable e)
				{	writeln(e.msg);
				
				}
				                                     
			                                    
				writeln(fff);
				auto response = dbase.query(fff); //запрос к БД
					auto похожиеФИО = response.getRecordSet(короткийФорматТурист); 
					//трансформирует ответ БД в RecordSet (набор записей)
			 числоСовпадений=похожиеФИО.length;
		  //table;//таблицаСовпадений;
		  if(числоСовпадений!=0)
			{
			table = `<table class="tab">`;
	table ~= `<tr>`;
   table ~= `<td> Ключ</td>`;
	
	table ~=`<td>Фамилия</td><td> Имя</td><td> Отчество</td><td> год рожд.</td><td>Править</td>`;

	
	foreach(rec; похожиеФИО)
	{	
	//raz_sud_kat= спортивныйРазряд [rec.get!"Разряд"(1000)] ~ `<br>`~ судейскаяКатегория[rec.get!"Категория"(1000)] ;
	
	   table ~= `<tr>`;
		table ~= `<td>` ~ rec.get!"ключ"(0).to!string ~ `</td>`;
		table ~= `<td>` ~ rec.get!"фамилия"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"имя"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"отчество"("")  ~ `</td>`;
		table ~= `<td>` ~ ( rec.isNull("год рожд") ? ``: rec.get!"год рожд"().to!string ) ~ `</td>`;
	   table ~= `<td> <a href="`~dynamicPath~`edit_tourist?key=`~rec.get!"ключ"(0).to!string~`">Изменить</a>  </td>`;
		
		table ~= `</tr>`;
	}
	
	table ~= `</table>`;

			
			}
			/*
				foreach(rec;похожиеФИО )
				{	writeln("СУПЕР_ПУПЕР_ПРОВЕРКА: ",
				     rec.get!"ключ"(),
				` `, rec.get!"фамилия"("") ,
				` `, rec.get!"имя"("") ,
				` `, rec.get!"отчество"(""),
				` `,( rec.isNull("год рожд") ? ``: rec.get!"год рожд"().to!string ),
				"\r\n");                                 
				}
				*/
					/*
					if( touristExistsQRes.recordCount != 0 )
					{	
						content = "Турист " ~ touristExistsQRes.get(0, 0) ~ " " ~ touristExistsQRes.get(1, 0) ~ " "
						~ " " ~ touristExistsQRes.get(2, 0) ~ " " ~ touristExistsQRes.get(3, 0) 
						~ " г.р. уже наличествует в базе данных!!!";
						tpl.set( "content", content );
						rp ~= tpl.getString();
					}
					*/
			}
			
			string queryStr;
			try
			{	string fieldNamesStr;  //имена полей для записи
				string fieldValuesStr; //значения полей для записи
				
			
				//Формирование запроса для записи строковых полей в БД
				foreach( i, fieldName; strFieldNames )
				{	string value = pVars.get(fieldName, null);
					if( value.length > 0  )
					{	fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
						fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) ~ "'" ~ PGEscapeStr(value) ~ "'"; 
					}
				}
				
				//Формирование запроса на запись даты рождения туриста
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
				
				//Формирование запроса на запись года рождения туриста
				auto birthYearStr = pVars.get("birth_year", null);
				if( birthYearStr.length > 0 )
				{	auto birthYear = birthYearStr.to!uint;
					fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"birth_year\"";
					fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ birthYear.to!string ~ "'";
				}
				
				//Логические значения
				//Показать телефон
				bool showPhone = toBool( pVars.get("show_phone", "no") );
				fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"show_phone\"";
				fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ ( showPhone ? "true" : "false" ) ~ "'";
				
				//Показать емэйл
				bool showEmail = toBool( pVars.get("show_email", "no") );
				fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"show_email\"";
				fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ ( showEmail ? "true" : "false" ) ~ "'";

				
				int sports_grade;
			try	{  sports_grade =  pVars.get("sports_grade", "1000").to!int; }
			catch(std.conv.ConvException e) {  sports_grade=1000;	};
							
				if (sports_grade  in спортивныйРазряд)
				{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"razr\"";
					fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("sports_grade", "") ~ "'";
				}
				else
					throw new std.conv.ConvException("Выражение \"" ~ pVars.get("sports_grade", "") ~ "\" не является значением типа \"спортивный разряд\"!!!");
					
				int	judge_category;					
				try	{  judge_category =  pVars.get("judge_category", "1000").to!int; }
			catch(std.conv.ConvException e) {  judge_category=1000;	};
							
				if (judge_category  in судейскаяКатегория)
				{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"sud\"";
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
			
			 if(числоСовпадений==0)	 {	dbase.query(queryStr);		 };
			
			//dbase.query(queryStr);//исполнение запроса//////////////////////////////////
			
			if( action == ActionType.insertData && числоСовпадений==0   )
			{	if( dbase.lastErrorMessage is null )
					content = "<h3>Данные о туристе успешно добавлены в базу данных!!!</h3>"
					~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
				else
					content = "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
					~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
					~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>";
			}
			else
			{	if( dbase.lastErrorMessage is null && числоСовпадений==0  )
					content = "<h3>Данные о туристе успешно обновлены!!!</h3>"
					~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
				else
					content = "<h3>Произошла ошибка при обновлении данных!!!</h3>"
					~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
					~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
			}
			
			if( числоСовпадений!=0 )
			{
			content ="<h3>В базе имеются похожие туристы</h3>"
					~ "Вы можете <a href=\"" ~ thisPagePath ~ "\">Добавить запись...</a><br>\r\nпродолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a><br>\r\n"
			      ~ " отредактировать одну из сушествующих записей в представленной таблице<br>\r\n"
			       ~table;
			       
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

