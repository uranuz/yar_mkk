module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.array, std.json, std.typecons, core.thread;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.view_logic.html_controls, webtank.common.optional;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, mkk_site._import;

immutable thisPagePath = dynamicPath ~ "edit_pohod";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(getTouristList);
	JSONRPCRouter.join!(списокУчастниковПохода);
}

alias FieldType ft;
auto shortTouristRecFormat = RecordFormat!( 
	ft.IntKey, "num", ft.Str, "family_name", 
	ft.Str, "given_name", ft.Str, "patronymic", ft.Int, "birth_year" 
)();

immutable shortTouristFormatQueryBase = 
	` select num, family_name, given_name, patronymic, birth_year from tourist `;

immutable touristInfoStringQueryBase = 
	` select coalesce(family_name, '') || coalesce(' ' || given_name, '') || coalesce(' ' || patronymic, '') || ', ' || coalesce(birth_year::text, 'null') || ' г.р' from tourist `;

//RPC метод для вывода списка туристов (с краткой информацией) по фильтру
auto getTouristList(string фамилия)
{	string result;
	auto dbase = getCommonDB();
	
	if ( !dbase.isConnected )
		return null; //Завершаем

	auto queryRes = dbase.query(  
		shortTouristFormatQueryBase ~ `where family_name ILIKE '`
		~ PGEscapeStr( фамилия ) ~ `%' limit 25;`
	);

	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	auto rs = queryRes.getRecordSet(shortTouristRecFormat);
	
	return rs;
}

auto списокУчастниковПохода( size_t pohodKey )
{	auto dbase = getCommonDB();
	if ( !dbase.isConnected )
		throw new Exception("База данных не доступна!!!"); //Завершаем
	
	auto queryRes = dbase.query(
`		with nums as (
			select unnest(unit_neim) as id from pohod where num=` ~ pohodKey.to!string ~ `
		)
		select num, family_name, given_name, patronymic, birth_year from tourist, nums
		where num=nums.id::bigint;
`	);

	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	return queryRes.getRecordSet(shortTouristRecFormat);
}


immutable(RecordFormat!(
	ft.IntKey, "num", ft.Str, "kod_mkk", ft.Str, "nomer_knigi", ft.Str, "region_pohod",
	ft.Str, "organization", ft.Str, "region_group", ft.Enum, "vid", ft.Enum, "elem",
	ft.Enum, "ks", ft.Str, "marchrut", ft.Date, "begin_date",
	ft.Date, "finish_date", ft.Int, "chef_grupp", ft.Int, "alt_chef",
	ft.Int, "unit", ft.Enum, "prepar", ft.Enum, "stat",
	ft.Str, "chef_coment", ft.Str, "MKK_coment", ft.Str, "unit_neim"
)) pohodRecFormat;


shared static this()
{	import webtank.common.utils;
	pohodRecFormat.enumFormats = 
	[	"vid": видТуризма,
		"ks": категорияСложности,
		"elem": элементыКС,
		"stat": статусЗаявки,
		"prepar": готовностьПохода
	];
}

immutable strFieldNames = [ "kod_mkk", "nomer_knigi", "region_pohod", "organization", "region_group", "marchrut" ].idup;

//Функция формирует форму редактирования похода
void создатьФормуИзмененияПохода(
	//Шаблон формы редактирования/ добавления похода
	PlainTemplater pohodForm, 
	
	//Запись с данными о существующем походе (если null - вставка нового похода)
	Record!( typeof(pohodRecFormat) ) pohodRec = null
)
{	
	if( pohodRec )
	{	//Выводим в браузер значения строковых полей (<input type="text">)
		foreach( fieldName; strFieldNames )
			pohodForm.set( fieldName, printHTMLAttr( "value", pohodRec.getStr(fieldName, "") ) );
	}

	//Создаём компонент выбора даты начала похода
	auto beginDatePicker = new PlainDatePicker;
	beginDatePicker.name = "begin"; //Задаём часть имени (компонент допишет _day, _year или _month)
	beginDatePicker.id = "begin"; //аналогично для id
	
	//Создаём компонент выбора даты завершения похода
	auto finishDatePicker = new PlainDatePicker;
	finishDatePicker.name = "finish";
	finishDatePicker.id = "finish";
	
	//Получаем данные о датах (если режим редактирования)
	if( pohodRec )
	{	//Извлекаем данные из БД
		if( !pohodRec.isNull("begin_date") )
			beginDatePicker.date = pohodRec.get!("begin_date");
		//Если данные не получены, то компонент выбора даты будет пустым
		
		if( !pohodRec.isNull("finish_date") )
			finishDatePicker.date = pohodRec.get!("finish_date");
	}
	
	pohodForm.set( "begin_date", beginDatePicker.print() );
	pohodForm.set( "finish_date", finishDatePicker.print() );
	
	if( pohodRec )
	{	pohodForm.set( "chef_coment", HTMLEscapeValue( pohodRec.get!"chef_coment"("") ) );
		pohodForm.set( "MKK_coment", HTMLEscapeValue( pohodRec.get!"MKK_coment"("") ) );
	}

	alias pohodRecFormat.filterNamesByTypes!(FieldType.Enum) pohodEnumFieldNames;
	//Вывод перечислимых полей
	foreach( fieldName; pohodEnumFieldNames )
	{	//Создаём экземпляр генератора выпадающего списка
		auto dropdown =  new PlainDropDownList;
		
		import webtank.common.utils;
		dropdown.values = pohodRecFormat.enumFormats[fieldName].mutCopy();
		dropdown.name = fieldName;
		dropdown.id = fieldName;

		//Задаём текущее значение
		if( pohodRec && !pohodRec.isNull(fieldName) )
			dropdown.currKey = pohodRec.get!(fieldName)();
		
		pohodForm.set( fieldName, dropdown.print() );
	}
	
	//Выводим руководителя похода и его зама
	if( pohodRec )
	{	auto dbase = getCommonDB();
	
		if( !dbase.isConnected )
			throw new Exception("База данных МКК не доступна!!!");
			
		if( pohodRec.isNull("chef_grupp") )
			pohodForm.set( "chef_grupp_text", "Редактировать");
		else {
			auto chefString_QRes = dbase.query( 
				touristInfoStringQueryBase ~ ` where num=` ~ pohodRec.get!("chef_grupp").to!string ~ `;` 
			);
			if( chefString_QRes.recordCount == 1 )
				pohodForm.set( "chef_grupp_text", chefString_QRes.get(0, 0) );
			else
				pohodForm.set( "chef_grupp_text", "Отсутствует в БД");
		}
		
		if( pohodRec.isNull("alt_chef") )
			pohodForm.set( "alt_chef_text", "Редактировать");
		else {
			auto chefString_QRes = dbase.query( 
				touristInfoStringQueryBase ~ ` where num=` ~ pohodRec.get!("alt_chef").to!string ~ `;`
			);
			if( chefString_QRes.recordCount == 1 )
				pohodForm.set( "alt_chef_text", chefString_QRes.get(0, 0) );
			else
				pohodForm.set( "alt_chef_text", "Отсутствует в БД");
		}
	}
	else
	{	pohodForm.set( "chef_grupp_text", "Редактировать");
		pohodForm.set( "alt_chef_text", "Редактировать");
	}
	
	//Задаём действие, чтобы при след. обращении к обработчику
	//перейти на этап записи в БД
	pohodForm.set( "form_input_action", ` value="write"` );
}


string изменитьДанныеПохода(HTTPContext context, Optional!size_t pohodKey)
{	
	auto rq = context.request;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	
	auto dbase = getCommonDB();
	
	if( !dbase.isConnected )
		throw new Exception("База данных МКК не доступна!!!");
	
	string fieldNamesStr;
	string fieldValuesStr;
	
	string[] allStringFields = strFieldNames ~ [ "chef_coment", "MKK_coment" ];
	
	//Формируем набор строковых полей и значений
	foreach( i, fieldName; allStringFields )
	{	if( fieldName !in pVars )
			continue;
			
		string value = pVars[fieldName];
		
		fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
		fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) 
			~ ( value.length == 0 ? "NULL" : "'" ~ PGEscapeStr(value) ~ "'" ); 
	}

	alias pohodRecFormat.filterNamesByTypes!(FieldType.Enum) pohodEnumFieldNames;
	
	//Формируем часть запроса для вывода перечислимых полей
	foreach( fieldName; pohodEnumFieldNames )
	{	if( fieldName !in pVars )
			continue;
			
		Optional!(int) enumKey;
		
		auto strKey = pVars[fieldName];
		if( strKey.length != 0 && toLower(strKey) != "null" )
		{	try {
				enumKey = strKey.to!int;
			} catch (std.conv.ConvException e) {
				throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
			}
		}
		
		if( !enumKey.isNull && enumKey !in pohodRecFormat.enumFormats[fieldName] )
			throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
	
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ fieldName ~ `"`;
			
		if( fieldValuesStr.length > 0 )
			fieldValuesStr ~= ", ";
		
		fieldValuesStr ~= enumKey.isNull ? "NULL" : enumKey.value.to!string;
	}
	
	//Формируем часть запроса для вбивания начальной и конечной даты
	import std.datetime;
	
	Optional!(Date)[2] pohodDates;
	string[2] dateParamNamePrefixes = ["begin_", "finish_"];
	
	foreach( i; 0..2 )
	{	string pre = dateParamNamePrefixes[i];
		
		if( 
			(pre ~ "year") !in pVars ||  
			(pre ~ "month") !in pVars ||
			(pre ~ "day") !in pVars
		) continue;

		string yearStr = pVars[ pre ~ "year" ];
		string monthStr = pVars[ pre ~ "month" ];
		string dayStr = pVars[ pre ~ "day" ];
		
		if( 
			yearStr.length != 0 && toLower(yearStr) != "null" ||
			monthStr.length != 0 && toLower(monthStr) != "null" ||
			dayStr.length != 0 && toLower(dayStr) != "null"
		)
		{	try {
				pohodDates[i] = Date(yearStr.to!int, monthStr.to!int, dayStr.to!int);
			}
			catch (std.conv.ConvException exc) 
			{	throw new Exception("Введенные компоненты дат не являются числовыми значениями");
				//TODO: Добавить обработку исключения
			} 
			catch (std.datetime.DateTimeException exc) 
			{	throw new Exception("Некорректный формат даты");
				//TODO: Добавить обработку исключения
				
			}
		}
	}

	if( !pohodDates[0].isNull && !pohodDates[1].isNull )
	{	if( pohodDates[1].value < pohodDates[0].value )
			throw new Exception("Дата начала похода должна быть раньше даты окончания");
	}
	
	foreach( i, pre; dateParamNamePrefixes )
	{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ pre ~ `date"`;
		fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) 
			~ ( pohodDates[i].isNull ? "NULL" : `'` ~ pohodDates[i].value.toISOExtString() ~ `'` );
	}
	
	//Разбор списка туристов
	if( "unit_neim" in pVars )
	{	import std.array;
		
		if( pVars["unit_neim"] != "null" && pVars["unit_neim"].length != 0 )
		{	auto touristKeyStrings = std.array.split(pVars["unit_neim"], ",");
			size_t[] touristKeys;
			
			foreach( keyStr; touristKeyStrings )
				touristKeys ~= keyStr.to!size_t; //Проверка на число
			
			auto existTouristCount_QRes = dbase.query(
				` with nums as ( select unnest( ARRAY[` ~ pVars["unit_neim"] ~ `] ) as n ) `
				~ ` select count(1) from tourist join nums on nums.n = tourist.num; `
			);
			
			if( existTouristCount_QRes.recordCount != 1 || existTouristCount_QRes.fieldCount != 1 )
				throw new Exception("Ошибка при запросе количества найденных записей о туристах!!!");
			
			size_t existTouristCount = existTouristCount_QRes.get(0, 0).to!size_t;
			if( existTouristCount != touristKeys.length )
				throw new Exception("Часть переданных в запросе ключей не соответствуют существующим в БД туристам!!!");
			
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `ARRAY[` ~ pVars["unit_neim"] ~ `]`;
		}
		else
		{	fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "NULL";
		}
		
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `unit_neim`;
	}
	
	//Бадяжим часть запроса для записи руководителя и его заместителя
	
	if( "chef_grupp" in pVars )
	{	if( pVars["chef_grupp"] != "null" && pVars["chef_grupp"].length != 0 )
		{	size_t chefGruppKey = pVars["chef_grupp"].to!size_t;
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ chefGruppKey.to!string;
		}
		else
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "NULL";
			
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `chef_grupp`;
	}
	
	if( "alt_chef" in pVars )
	{	if( pVars["alt_chef"] != "null" && pVars["alt_chef"].length != 0 )
		{	size_t chefGruppKey = pVars["alt_chef"].to!size_t;
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ chefGruppKey.to!string;
		}
		else
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "NULL";
			
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `alt_chef`;
	}
	
	//Запись автора последних изменений и даты этих изменений
	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `last_editor_num, last_edit_timestamp` ;
	fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ context.user.data["user_num"] ~ `, current_timestamp`;
	
	//Формирование и выполнение запроса к БД
	string queryStr;
	
	if( pohodKey.isNull )
	{	//Запись пользователя, добавившего поход и даты добавления
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `registrator_num, reg_timestamp` ;
		fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ context.user.data["user_num"] ~ `, current_timestamp`;
		queryStr = "insert into pohod ( " ~ fieldNamesStr ~ " ) values( " ~ fieldValuesStr ~ " );";
	}
	else
	{
		queryStr = "update pohod set( " ~ fieldNamesStr ~ " ) = ( " ~ fieldValuesStr ~ " ) where num='" ~ pohodKey.value.to!string ~ "';";
	}
	auto writeDBQueryRes = dbase.query(queryStr);
	
	string message;
	
	if( pohodKey.isNull  )
	{	if( dbase.lastErrorMessage is null )
			message = "<h3>Данные о походе успешно добавлены в базу данных!!!</h3>"
			~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
		else
			message = "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
			~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
			~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>\r\n";
	}
	else
	{	if( dbase.lastErrorMessage is null )
			message = "<h3>Данные о походе успешно обновлены!!!</h3>"
			~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ pohodKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
			~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
		else
			message = "<h3>Произошла ошибка при обновлении данных!!!</h3>"
			~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
			~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ pohodKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
			~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>\r\n";
	}
	
	return message;
}


void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
		
	bool isAuthorized = 
		context.user.isAuthenticated && 
		( context.user.isInRole("moder") || context.user.isInRole("admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаем шаблон по файлу
		auto tpl = getGeneralTemplate(context);
	
		auto dbase = getCommonDB;
		if ( !dbase.isConnected )
		{	tpl.set( "content", "<h3>База данных МКК не доступна!</h3>" );
			rp ~= tpl.getString();
			return; //Завершаем
		}
		
		Optional!size_t pohodKey;
		try {
			pohodKey = qVars.get("key", null).to!size_t;
		}
		catch(std.conv.ConvException e)
		{	pohodKey = null; }

		Record!( typeof(pohodRecFormat) ) pohodRec;
		RecordSet!( typeof(shortTouristRecFormat) ) touristRS;
		
		//Если в принципе ключ является числом, то получаем данные из БД
		if( !pohodKey.isNull )
		{	auto pohodRS = dbase.query( 
				`select num, kod_mkk, nomer_knigi, region_pohod, organization, region_group, vid, elem, ks, marchrut, begin_date, finish_date, chef_grupp, alt_chef, unit, prepar, stat, chef_coment, "MKK_coment", unit_neim from pohod where num=` ~ pohodKey.value.to!string ~ `;`
			).getRecordSet(pohodRecFormat);
			if( ( pohodRS !is null ) && ( pohodRS.length == 1 ) ) //Если получили одну запись -> ключ верный
				pohodRec = pohodRS.front;
			else
				pohodKey = null;
		}
		
		auto pohodForm = getPageTemplate( pageTemplatesDir ~ "edit_pohod_form.html" );
		//pohodForm.set( "form_action", thisPagePath );
		
		string editResultMessage;
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
			editResultMessage = изменитьДанныеПохода(context, pohodKey);
		
		создатьФормуИзмененияПохода(pohodForm, pohodRec);

		string content = editResultMessage ~ pohodForm.getString();
		
		tpl.set( "content", content );
		rp ~= tpl.getString();
	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}
