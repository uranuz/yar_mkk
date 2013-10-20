module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.stdio, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "edit_pohod";
immutable authPagePath = dynamicPath ~ "auth";

static this()
{	Router.setPathHandler(thisPagePath, &netMain);
	Router.setRPCMethod("турист.список_по_фильтру", &getTouristList);
// 	Router.setRPCMethod("поход.окно_редактирования_участников", &getParticipantsEditWindow);
	Router.setRPCMethod("поход.список_участников", &getPohodParticipants);
}

//RPC метод для вывода списка туристов (с краткой информацией) по фильтру
auto getTouristList(string filterStr)
{	string result;
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	
	if ( !dbase.isConnected )
		return null; //Завершаем

	string queryStr1 = `select num, family_name, given_name, patronymic, birth_year from tourist where family_name ILIKE '`
		~ PGEscapeStr( filterStr ) ~ `%' limit 25;`;
	auto queryRes1 = dbase.query( queryStr1 );
	if( queryRes1 is null || queryRes1.recordCount == 0 )
		return null;
	
	alias FieldType ft;
	auto touristRecFormat = RecordFormat!( ft.IntKey, "num", ft.Str, "family_name", 
		ft.Str, "given_name", ft.Str, "patronymic", ft.Int, "birth_year" )();
	
	auto touristRS = queryRes1.getRecordSet(touristRecFormat);
	return touristRS;
}

auto getPohodParticipants( size_t pohodNum, uint requestedLimit )
{	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null; //Завершаем
	
	uint maxLimit = 25;
	uint limit = ( requestedLimit < maxLimit ? requestedLimit : maxLimit );
	
	auto queryRes = dbase.query(
		`select num, family_name, given_name, patronymic, birth_year from tourist where num=`
		~ pohodNum.to!string ~ ` limit ` ~ limit.to!string ~ `;`
	);
	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	alias FieldType ft;
	auto touristRecFormat = RecordFormat!( ft.IntKey, "num", ft.Str, "family_name", 
		ft.Str, "given_name", ft.Str, "patronymic", ft.Int, "birth_year" )();
	
	auto touristRS = queryRes.getRecordSet(touristRecFormat);
	

	return touristRS;
}



void netMain(ServerRequest rq, ServerResponse rp)  //Определение главной функции приложения
{	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	
	auto auth = new Authentication( rq.cookie.get("sid", null), authDBConnStr, eventLogFileName );
	
	bool isAuthorized = auth.isIdentified() && ( (auth.userInfo.group == "moder") || (auth.userInfo.group == "admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства	
		string generalTplStr = cast(string) std.file.read( generalTemplateFileName );
		
		//Создаем шаблон по файлу
		auto tpl = getGeneralTemplate(thisPagePath);

		tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ auth.userInfo.name ~ "</b>!!!</i>");
		tpl.set("user login", auth.userInfo.login );
	
		auto dbase = new DBPostgreSQL(commonDBConnStr);
		if ( !dbase.isConnected )
		{	tpl.set( "content", "<h3>База данных МКК не доступна!</h3>" );
			rp ~= tpl.getString();
			return; //Завершаем
		}
		
		//Пытаемся получить ключ
		bool isPohodKeyAccepted = false;
		
		size_t pohodKey;
		try {
			pohodKey = qVars.get("key", null).to!size_t;
			isPohodKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isPohodKeyAccepted = false; }
		
		alias FieldType ft;
		auto pohodRecFormat = RecordFormat!(
			ft.IntKey, "num", ft.Str, "kod_mkk", ft.Str, "nomer_knigi", ft.Str, "region_pohod",
			ft.Str, "organization", ft.Str, "region_group", ft.Str, "vid", ft.Str, "element",
			ft.Str, "ks", ft.Str, "marchrut", ft.Date, "begin_date",
			ft.Date, "finish_date", ft.Str, "chef_group", ft.Str, "alt_chef",
			ft.Int, "unit", ft.Str, "prepare", ft.Str, "status",
			ft.Str, "chef_coment", ft.Str, "MKK_coment", ft.Str, "unit_neim"
		)();
		
		auto touristRecFormat = RecordFormat!( ft.IntKey, "num", ft.Str, "family_name", 
		ft.Str, "given_name", ft.Str, "patronymic", ft.Int, "birth_year" )();
		
		Record!( typeof(pohodRecFormat) ) pohodRec;
		RecordSet!( typeof(touristRecFormat) ) touristRS;
		
		//Если в принципе ключ является числом, то получаем данные из БД
		if( isPohodKeyAccepted )
		{	auto pohodRS = dbase.query( 
				`select num, kod_mkk, nomer_knigi, region_pohod, organization, region_group, vid, element, ks, marchrut, begin_date, finish_date, chef_grupp, alt_chef, unit, prepare, status, chef_coment, "MKK_coment", unit_neim from pohod where num=` ~ pohodKey.to!string ~ `;`
			).getRecordSet(pohodRecFormat);
			if( ( pohodRS !is null ) && ( pohodRS.length == 1 ) ) //Если получили одну запись -> ключ верный
			{	pohodRec = pohodRS.front;
				isPohodKeyAccepted = true;
				//Получаем информацию об участниках похода
				//Скобочки {} в начале и в конце строкового представления массива
				if( pohodRec.get!"unit_neim"("").length >= 2 ) 
					touristRS = dbase.query(
						` with nums as ( select unnest( string_to_array('` 
						~ PGEscapeStr( (pohodRec.get!"unit_neim"(""))[1..$-1] ) ~ `', ',') ) as id ) ` //вырезали скобочки
						~ ` select num, family_name, given_name, patronymic, birth_year from tourist, nums ` 
						~ ` where num=nums.id::bigint;`
					).getRecordSet(touristRecFormat);
			}
			else
				isPohodKeyAccepted = false;
		}
		writeln("Тест11");
		//Перечислимый тип, который определяет выполняемое действие
		enum ActionType { showInsertForm, showUpdateForm, insertData, updateData };
		
		ActionType action;
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
			action = ( isPohodKeyAccepted ? ActionType.updateData : ActionType.insertData );
		else
			action = ( isPohodKeyAccepted ? ActionType.showUpdateForm : ActionType.showInsertForm );

		string pohodFormTplStr = cast(string) std.file.read( pageTemplatesDir ~ "edit_pohod_form.html" );
		
		auto pohodForm = new PlainTemplater( pohodFormTplStr );
		
		enum string[] months = [ "январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь" ];
		
		enum string[][string] enumValueBlocks = [
			"vid": [ "", "пешеходный", "лыжный", "горный", "водный", "велосипедный", "автомото", "спелео", "парусрый", "конный", "комбинированный" ],
			"element": [ "", "с эл.1", "с эл.2", "с эл.3", "с эл.4", "с эл.5", "с эл.6" ],
			"ks": [ "", "п.в.д.", "н.к.", "первая", "вторая", "третья", "четвёртая", "пятая", "шестая", "путешествие" ],
			"prepare": [ "", "планируется", "готовится", "набор группы", "набор завершон", "на маршруте", "пройден" ],
			"status": [ "", "рассматривается", "заявлен", "на контроле", "пройден", "засчитан" ]
		];
		
		enum strFieldNames = [ "kod_mkk", "nomer_knigi", "region_pohod", "organization", "region_group", "marchrut" ];
		
		string content;
		
		if( action == ActionType.showUpdateForm )
		{	
			writeln("Тест12");
			//Выводим в браузер значения строковых полей (<input type="text">)
			foreach( fieldName; strFieldNames )
				pohodForm.set( fieldName, ` value="` ~ HTMLEscapeValue( pohodRec.getStr(fieldName, "") ) ~ `"` );

			writeln("Тест13");
			/+pohodForm.set( "num.value", pohodRec.get!"ключ"(0).to!string );+/
			//Выводим дату начала похода
 			pohodForm.set( "begin_day", ` value="` ~ pohodRec.get!("begin_date").day.to!string ~ `"` );
 			///!!! Месяц выводится далее
 			pohodForm.set( "begin_year", ` value="` ~ pohodRec.get!("begin_date").year.to!string ~ `"` );
 			
 			//Выводим дату конца похода
 			pohodForm.set( "finish_day", ` value="` ~ pohodRec.get!("finish_date").day.to!string ~ `"` );
 			///!!! Месяц выводится далее
 			pohodForm.set( "finish_year", ` value="` ~ pohodRec.get!("finish_date").year.to!string ~ `"` );
 
			string touristListStr;
			foreach( rec; touristRS )
			{	touristListStr ~= HTMLEscapeValue( rec.get!"family_name"("") ) ~ " "
					~ HTMLEscapeValue( rec.get!"given_name"("") ) ~ " " ~ HTMLEscapeValue( rec.get!"patronymic"("") )
					~ ( rec.isNull("birth_year") ? "" : (", " ~ rec.get!"birth_year"(0).to!string ~ " г.р") ) ~ "<br>\r\n";
			}
			
			
 			pohodForm.set( "unit", touristListStr );
 			pohodForm.set( "chef_coment", HTMLEscapeValue( pohodRec.get!"chef_coment"("") ) );
 			pohodForm.set( "MKK_coment", HTMLEscapeValue( pohodRec.get!"MKK_coment"("") ) );
 			
 		}
 		
 		if( action == ActionType.showUpdateForm || action == ActionType.showInsertForm )
 		{	import std.string;
			if( action == ActionType.showInsertForm )
			{	//TODO: Проверка наличия похода в базе
			}
			
			//Выводим месяц начала похода в форму
			ubyte beginMonth;
			if( action == ActionType.showUpdateForm )
				beginMonth = ( pohodRec.isNull("begin_date") ? 0 : pohodRec.get!("begin_date").month );
			auto beginMonthInp = `<option value=""` ~ ( ( beginMonth == 0 || beginMonth > 31 ) ? ` selected` : `` ) ~ `></option>`;
			foreach( i; 1..12 )
			{	beginMonthInp ~= `<option value="` ~ i.to!string ~ `"`
				~ ( beginMonth == i ? ` selected` : ``) 
				~ `>` ~ i.to!string ~ `</option>`;
			}
			pohodForm.set( "begin_month", beginMonthInp );
			
			//Выводим месяц окончания похода
			ubyte finishMonth;
			if( action == ActionType.showUpdateForm )
				finishMonth = ( pohodRec.isNull("finish_date") ? 0 : pohodRec.get!("finish_date").month );
			auto finishMonthInp = `<option value=""` ~ ( ( finishMonth == 0 || finishMonth > 31 ) ? ` selected` : `` ) ~ `></option>`;
			foreach( i; 1..12 )
			{	finishMonthInp ~= `<option value="` ~ i.to!string ~ `"`
				~ ( finishMonth == i ? ` selected` : ``) 
				~ `>` ~ i.to!string ~ `</option>`;
			}
			pohodForm.set( "finish_month", finishMonthInp );
 		
			foreach( fieldName, valueBlock; enumValueBlocks )
			{	string inputField;
				foreach( value; valueBlock )
				{	inputField ~= `<option value="` ~ value ~ `"`;
					if( action == ActionType.showUpdateForm )
						inputField ~= ( (pohodRec.getStr(fieldName, "") == value) ? " selected" : "" );
					inputField ~= `>` ~ value ~ `</option>`;
				}
				pohodForm.set( fieldName, inputField );
			}
 			
 			pohodForm.set( "action", ` value="write"` );
 			
 			content = pohodForm.getString();
		}
		
		if( action == ActionType.insertData || action == ActionType.updateData )
		{	import std.conv, std.algorithm;
			string queryStr;
			try
			{	string fieldNamesStr;
				string fieldValuesStr;
				
				//Формируем набор строковых полей и значений
				foreach( i, fieldName; strFieldNames )
				{	string value = pVars.get(fieldName, null);
					if( value.length > 0  )
					{	fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
						fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) ~ "'" ~ PGEscapeStr(value) ~ "'"; 
					}
				}
				
				//Формируем часть запроса для вывода перечислимых полей
				foreach( fieldName, valueBlock; enumValueBlocks )
				{	if( find( valueBlock, pVars.get(fieldName, "") ).length > 0  )
					{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ fieldName ~ `"`;
						fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `'` ~ pVars.get(fieldName, "") ~ `'`;
					}
					else
						throw new std.conv.ConvException("Выражение \"" ~ pVars.get("vid", "") ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
				}
				
				//Формируем часть запроса для вбивания начальной и конечной даты
				foreach( i; 0..1 )
				{	auto pre = ( i == 0 ? "begin_" : "end_" );
					if( pVars.get( pre ~ "year", "" ).length > 0  &&
						pVars.get( pre ~ "month", "").length > 0  &&
						pVars.get( pre ~ "day", "").length > 0
					)
					{	import std.datetime;
						auto date = Date( 
							pVars.get( pre ~ "year", "").to!int,
							pVars.get( pre ~ "month", "").to!int,
							pVars.get( pre ~ "day", "").to!int
						);
						fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ pre ~ `date"`;
						fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `'` ~ date.toISOExtString() ~ `'`;
					}
				}
				
 
// 				size_t moderKey = postVars.get("moder", "").to!size_t;
// 				~ moderKey.to!string ~ ", "
				if( fieldNamesStr.length > 0 && fieldValuesStr.length > 0 )
				{	if( action == ActionType.insertData )
						queryStr = "insert into pohod ( " ~ fieldNamesStr ~ " ) values( " ~ fieldValuesStr ~ " );";
					else
						queryStr = "update pohod set( " ~ fieldNamesStr ~ " ) = ( " ~ fieldValuesStr ~ " ) where num='" ~ pohodKey.to!string ~ "';";
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
					content = "<h3>Данные о походе успешно добавлены в базу данных!!!</h3>"
					~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
				else
					content = "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
					~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
					~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>";
			}
			else
			{	if( dbase.lastErrorMessage is null )
					content = "<h3>Данные о походе успешно обновлены!!!</h3>"
					~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ pohodKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_pohod\">к списку походов</a>";
				else
					content = "<h3>Произошла ошибка при обновлении данных!!!</h3>"
					~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
					~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ pohodKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
					~ "или перейти <a href=\"" ~ dynamicPath ~ "show_pohod\">к списку походов</a>";
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
