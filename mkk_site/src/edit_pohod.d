module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.stdio, std.array, std.json, std.typecons;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.view_logic.html_controls, webtank.common.optional;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils, mkk_site._import;

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

//RPC метод для вывода списка туристов (с краткой информацией) по фильтру
auto getTouristList(string фамилия)
{	string result;
	auto dbase = getCommonDB();
	
	writeln("edit_pohod.getTouristList test 0");
	
	if ( !dbase.isConnected )
		return null; //Завершаем

	auto queryRes = dbase.query(  
		shortTouristFormatQueryBase ~ `where family_name ILIKE '`
		~ PGEscapeStr( фамилия ) ~ `%' limit 25;`
	);
	
	writeln("getTouristList test 10");
	
	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	writeln("getTouristList test 20");
	
	auto rs = queryRes.getRecordSet(shortTouristRecFormat);
	writeln("getTouristList test 30");
	
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
	ft.Date, "finish_date", ft.Str, "chef_group", ft.Str, "alt_chef",
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
	Record!( typeof(pohodRecFormat) ) pohodRec = null,
	
	//Набор записей о туристах, участвующих в походе
	RecordSet!( typeof(shortTouristRecFormat) ) touristRS = null
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
			beginDatePicker.date = pohodRec.get!("finish_date");
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
	
	writeln("изменитьДанныеПохода test 20");
	
	//Формируем набор строковых полей и значений
	foreach( i, fieldName; strFieldNames )
	{	if( fieldName !in pVars )
			continue;
			
		string value = pVars[fieldName];
		
		fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
		fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) 
			~ ( value.length == 0 ? "NULL" : "'" ~ PGEscapeStr(value) ~ "'" ); 
	}
	
	writeln("изменитьДанныеПохода test 30");
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
	
	writeln("изменитьДанныеПохода test 40");
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
	
	string queryStr;
	
	if( pohodKey.isNull )
		queryStr = "insert into pohod ( " ~ fieldNamesStr ~ " ) values( " ~ fieldValuesStr ~ " );";
	else
		queryStr = "update pohod set( " ~ fieldNamesStr ~ " ) = ( " ~ fieldValuesStr ~ " ) where num='" ~ pohodKey.value.to!string ~ "';";
		
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
	
	writeln("fieldNamesStr: ", fieldNamesStr);
	writeln("fieldValuesStr: ", fieldValuesStr);
	writeln("queryStr", queryStr);
	
	return message;
}


void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
		
	bool isAuthorized = 
		context.accessTicket.isAuthenticated && 
		( context.accessTicket.user.isInGroup("moder") || context.accessTicket.user.isInGroup("admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаем шаблон по файлу
		auto tpl = getGeneralTemplate(thisPagePath);

		if( context.accessTicket.isAuthenticated )
		{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.accessTicket.user.name ~ "</b>!!!</i>");
			tpl.set("user login", context.accessTicket.user.login );
		}
		else 
		{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
		}
	
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
		pohodForm.set( "form_action", thisPagePath );
		
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
