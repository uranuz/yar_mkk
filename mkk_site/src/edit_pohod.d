module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.stdio, std.array, std.json, std.typecons;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.view_logic.html_controls;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils, mkk_site._import;

immutable thisPagePath = dynamicPath ~ "edit_pohod";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(getTouristList);

// 	Router.setRPCMethod("поход.список_участников", &getParticipantsEditWindow);
// 	Router.setRPCMethod("поход.создать_поход", &createPohod);
// 	Router.setRPCMethod("поход.обновить_поход", &updatePohod);
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
// 
// 
// 
// auto getPohodParticipants( size_t pohodNum, uint requestedLimit )
// {	auto dbase = getCommmonDB();
// 	if ( !dbase.isConnected )
// 		return null; //Завершаем
// 	
// 	uint maxLimit = 25;
// 	uint limit = ( requestedLimit < maxLimit ? requestedLimit : maxLimit );
// 	
// 	auto queryRes = dbase.query(
// 		shortTouristFormatQueryBase ~ `where num=`
// 		~ pohodNum.to!string ~ ` limit ` ~ limit.to!string ~ `;`
// 	);
// 	if( queryRes is null || queryRes.recordCount == 0 )
// 		return null;
// 	
// 	return queryRes.getRecordSet(shortTouristRecFormat);
// }

// import std.typecons, std.typetuple;
// alias TypeTuple!(
// 	string, "kod_mkk", string, "nomer_knigi", string, "region_pohod", string, "organization", string, "organization", string, "vid", string, "element", string, "ks", string, "marchrut", string, "begin_date", string, "finish_date", string, "chef_grupp", string, "alt_chef", string, "unit", string, "prepare", string, "status", string, "emitter", string, "chef_coment", string, "MKK_coment", size_t[], "unit_neim"
// ) PohodTupleType;

// string[int][string] initializePohodEnumValues()
// {	string[int][string] result;
// 	result["vid"] = видТуризма;
// 	result["element"] = элементыКС;
// 	result["ks"] = категорияСложности;
// 	result["prepare"] = готовностьПохода;
// 	result["status"] = статусЗаявки;
// 
// 	return result;
// }
// 
// alias enum string[int] PohodEnumType;
// 
// enum PohodEnumType[string] pohodEnumValues = initializePohodEnumValues();

immutable(RecordFormat!(
	ft.IntKey, "num", ft.Str, "kod_mkk", ft.Str, "nomer_knigi", ft.Str, "region_pohod",
	ft.Str, "organization", ft.Str, "region_group", ft.Enum, "vid", ft.Enum, "element",
	ft.Enum, "ks", ft.Str, "marchrut", ft.Date, "begin_date",
	ft.Date, "finish_date", ft.Str, "chef_group", ft.Str, "alt_chef",
	ft.Int, "unit", ft.Enum, "prepare", ft.Enum, "status",
	ft.Str, "chef_coment", ft.Str, "MKK_coment", ft.Str, "unit_neim"
)) pohodRecFormat;


shared static this()
{	import webtank.common.utils;
	pohodRecFormat.enumFormats = 
	[	"vid": видТуризма,
		"ks": категорияСложности,
		"element": элементыКС,
		"prepare": готовностьПохода,
		"status": статусЗаявки
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
	
	/+pohodForm.set( "num.value", pohodRec.get!"ключ"(0).to!string );+/
	
	if( touristRS )
	{	string touristListStr;
		foreach( rec; touristRS )
		{	touristListStr ~= HTMLEscapeValue( rec.get!"family_name"("") ) ~ " "
				~ HTMLEscapeValue( rec.get!"given_name"("") ) ~ " " ~ HTMLEscapeValue( rec.get!"patronymic"("") )
				~ ( rec.isNull("birth_year") ? "" : (", " ~ rec.get!"birth_year"(0).to!string ~ " г.р") ) ~ "<br>\r\n";
		}
		pohodForm.set( "unit", touristListStr );
	}
	
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


void изменитьДанныеПохода(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	
	string fieldNamesStr;
	string fieldValuesStr;
	
	writeln("изменитьДанныеПохода test 20");
	
	//Формируем набор строковых полей и значений
	foreach( i, fieldName; strFieldNames )
	{	string value = pVars.get(fieldName, null);
		if( value.length > 0  )
		{	fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
			fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) ~ "'" ~ PGEscapeStr(value) ~ "'"; 
		}
	}
	
	alias pohodRecFormat.filterNamesByTypes!(FieldType.Enum) pohodEnumFieldNames;
	
	//Формируем часть запроса для вывода перечислимых полей
	foreach( fieldName; pohodEnumFieldNames )
	{	int enumKey;
		try {
			enumKey = pVars.get(fieldName, "").to!int;
		} catch (std.conv.ConvException e) {
// 			enumKey.nullify();
		}
		
		writeln(enumKey);
		
// 		if(  )
		
		if( enumKey in pohodRecFormat.enumFormats[fieldName] )
		{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ fieldName ~ `"`;
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `'` ~ pVars.get(fieldName, "") ~ `'`;
		}
		else
			throw new std.conv.ConvException("Выражение \"" ~ pVars.get("vid", "") ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
	}
	
	//Формируем часть запроса для вбивания начальной и конечной даты
	foreach( i; 0..1 )
	{	auto pre = ( i == 0 ? "begin_" : "end_" );
		import std.datetime;
		Date date;
		try {
			date = Date( 
				pVars.get( pre ~ "year", "").to!int,
				pVars.get( pre ~ "month", "").to!int,
				pVars.get( pre ~ "day", "").to!int
			);
		} 
		catch (std.conv.ConvException exc) 
		{	throw exc;
			//TODO: Добавить обработку исключения
		} 
		catch (std.datetime.DateTimeException exc) 
		{	throw exc;
			//TODO: Добавить обработку исключения
		}
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ pre ~ `date"`;
		fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `'` ~ date.toISOExtString() ~ `'`;
	}
	
	writeln("fieldNamesStr: ", fieldNamesStr);
	writeln("fieldValuesStr: ", fieldValuesStr);
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
		
		//Пытаемся получить ключ
		bool isPohodKeyAccepted = false;
		
		size_t pohodKey;
		try {
			pohodKey = qVars.get("key", null).to!size_t;
			isPohodKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isPohodKeyAccepted = false; }

		Record!( typeof(pohodRecFormat) ) pohodRec;
		RecordSet!( typeof(shortTouristRecFormat) ) touristRS;
		
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
					).getRecordSet(shortTouristRecFormat);
			}
			else
				isPohodKeyAccepted = false;
		}
		
		auto pohodForm = getPageTemplate( pageTemplatesDir ~ "edit_pohod_form.html" );
		pohodForm.set( "form_action", thisPagePath );
		
		
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
		{	writeln("mkk_site.edit_pohod.netMain write test 20");
			изменитьДанныеПохода(context);
			
		}
		else
		{	создатьФормуИзмененияПохода(pohodForm, pohodRec, touristRS);
			
		}

		string content = pohodForm.getString();
		
		tpl.set( "content", content );
		rp ~= tpl.getString();

	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}
