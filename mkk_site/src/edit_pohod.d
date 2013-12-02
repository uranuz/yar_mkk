module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.stdio, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.view_logic.html_controls;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "edit_pohod";
immutable authPagePath = dynamicPath ~ "auth";

static this()
{	
	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
// 	Router.join( new JSON_RPC_HandlingRule!() );
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

// //RPC метод для вывода списка туристов (с краткой информацией) по фильтру
// auto getTouristList(string filterStr)
// {	string result;
// 	auto dbase = getCommmonDB();
// 	
// 	if ( !dbase.isConnected )
// 		return null; //Завершаем
// 
// 	auto queryRes = dbase.query(  
// 		shortTouristFormatQueryBase ~ `where family_name ILIKE '`
// 		~ PGEscapeStr( filterStr ) ~ `%' limit 25;`
// 	);
// 	if( queryRes is null || queryRes.recordCount == 0 )
// 		return null;
// 	
// 	return queryRes.getRecordSet(shortTouristRecFormat);
// }
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
	writeln("ФормаИзмПохода10");
	if( pohodRec )
	{	//Выводим в браузер значения строковых полей (<input type="text">)
		foreach( fieldName; strFieldNames )
			pohodForm.set( fieldName, printHTMLAttr( "value", pohodRec.getStr(fieldName, "") ) );
	}

	writeln("ФормаИзмПохода20");
	//Создаём компонент выбора даты начала похода
	auto beginDatePicker = new PlainDatePicker;
	beginDatePicker.name = "begin"; //Задаём часть имени (компонент допишет _day, _year или _month)
	beginDatePicker.id = "begin"; //аналогично для id
	
	writeln("ФормаИзмПохода30");
	//Создаём компонент выбора даты завершения похода
	auto finishDatePicker = new PlainDatePicker;
	finishDatePicker.name = "finish";
	finishDatePicker.id = "finish";
	
	writeln("ФормаИзмПохода40");
	//Получаем данные о датах (если режим редактирования)
	if( pohodRec )
	{	//Извлекаем данные из БД
		if( !pohodRec.isNull("begin_date") )
			beginDatePicker.date = pohodRec.get!("begin_date");
		//Если данные не получены, то компонент выбора даты будет пустым
		
		if( !pohodRec.isNull("finish_date") )
			beginDatePicker.date = pohodRec.get!("finish_date");
	}
	
	writeln("ФормаИзмПохода50");
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
	{	writeln("pohodRec is not null!!");
		pohodForm.set( "chef_coment", HTMLEscapeValue( pohodRec.get!"chef_coment"("") ) );
		pohodForm.set( "MKK_coment", HTMLEscapeValue( pohodRec.get!"MKK_coment"("") ) );
	}
	writeln("ФормаИзмПохода60");
	alias pohodRec.FormatType.filterNamesByTypes!(FieldType.Enum) pohodEnumFieldNames;
	
	pragma(msg, "pohodEnumFieldNames: ", pohodEnumFieldNames);
	
	
	
	//Вывод перечислимых полей
	foreach( fieldName; pohodEnumFieldNames )
	{	pragma(msg, "Current field name is: ");
		pragma(msg, fieldName);
		
		writeln("ФормаИзмПохода65");
		
		//Создаём экземпляр генератора выпадающего списка
		auto dropdown =  new PlainDropDownList;
		
		writeln("ФормаИзмПохода66");
		import webtank.common.utils;
		const(EnumFormat) enumFormatC = pohodRec.getEnumFormat!(fieldName)();
		writeln("ФормаИзмПохода66а");
		EnumFormat enumFormat = enumFormatC.mutCopy();
		writeln("enumForamt", enumFormat);
		dropdown.values = enumFormat;
		writeln("ФормаИзмПохода67");
		dropdown.name = fieldName;
		dropdown.id = fieldName;
		
		writeln("ФормаИзмПохода68");
		//Задаём текущее значение
		if( !pohodRec.isNull(fieldName) )
		{	writeln("ФормаИзмПохода69");
			dropdown.currKey = pohodRec.get!(fieldName)();
			writeln("ФормаИзмПохода69а");
		}
		
		writeln("ФормаИзмПохода69б");
		pohodForm.set( fieldName, dropdown.print() );
		writeln("ФормаИзмПохода69в");
	}
	writeln("ФормаИзмПохода70");
	
	//Задаём действие, чтобы при след. обращении к обработчику
	//перейти на этап записи в БД
	pohodForm.set( "action", ` value="write"` );
	writeln("pohodForm.getStr()", pohodForm.getString());
}


// void изменитьДанныеПохода(HTTPContext context)
// {	
// 	auto rq = context.request;
// 	auto rp = context.response;
// 	
// 	auto pVars = rq.postVars;
// 	auto qVars = rq.queryVars;
// 	
// 	string fieldNamesStr;
// 	string fieldValuesStr;
// 	
// 	//Формируем набор строковых полей и значений
// 	foreach( i, fieldName; strFieldNames )
// 	{	string value = pVars.get(fieldName, null);
// 		if( value.length > 0  )
// 		{	fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
// 			fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) ~ "'" ~ PGEscapeStr(value) ~ "'"; 
// 		}
// 	}
// 	
// 	//Формируем часть запроса для вывода перечислимых полей
// 	foreach( fieldName, valueBlock;  pohodEnumValues )
// 	{	int enumKey = 0;
// 		try {
// 			enumKey = pVars.get(fieldName, "").to!int;
// 		} catch (std.conv.ConvException e) {
// 			
// 		}
// 		
// 		if( enumKey in valueBlock )
// 		{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ fieldName ~ `"`;
// 			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `'` ~ pVars.get(fieldName, "") ~ `'`;
// 		}
// 		else
// 			throw new std.conv.ConvException("Выражение \"" ~ pVars.get("vid", "") ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
// 	}
// 	
// 	//Формируем часть запроса для вбивания начальной и конечной даты
// 	foreach( i; 0..1 )
// 	{	auto pre = ( i == 0 ? "begin_" : "end_" );
// 		import std.datetime;
// 		Date date;
// 		try {
// 			date = Date( 
// 				pVars.get( pre ~ "year", "").to!int,
// 				pVars.get( pre ~ "month", "").to!int,
// 				pVars.get( pre ~ "day", "").to!int
// 			);
// 		} 
// 		catch (std.conv.ConvException exc) 
// 		{	throw exc;
// 			//TODO: Добавить обработку исключения
// 		} 
// 		catch (std.datetime.DateTimeException exc) 
// 		{	throw exc;
// 			//TODO: Добавить обработку исключения
// 		}
// 		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ `"` ~ pre ~ `date"`;
// 		fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ `'` ~ date.toISOExtString() ~ `'`;
// 	}
// 	
// }


void netMain(HTTPContext context)
{	
	auto rq = context.request;
	auto rp = context.response;
	
	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
		
	bool isAuthorized = 
		context.accessTicket.isAuthenticated && 
		( context.accessTicket.user.isInGroup("moder") || context.accessTicket.user.isInGroup("admin") );
		
	writeln("test10");
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		writeln("test20");
		//Создаем шаблон по файлу
		auto tpl = getGeneralTemplate(thisPagePath);

		if( context.accessTicket.isAuthenticated )
		{	tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ context.accessTicket.user.name ~ "</b>!!!</i>");
			tpl.set("user login", context.accessTicket.user.login );
		}
		else 
		{	tpl.set("auth header message", "<i>Вход не выполнен</i>");
		}
		writeln("test30");
	
		auto dbase = getCommmonDB;
		if ( !dbase.isConnected )
		{	tpl.set( "content", "<h3>База данных МКК не доступна!</h3>" );
			rp ~= tpl.getString();
			return; //Завершаем
		}
		writeln("test40");
		
		//Пытаемся получить ключ
		bool isPohodKeyAccepted = false;
		
		size_t pohodKey;
		try {
			pohodKey = qVars.get("key", null).to!size_t;
			isPohodKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isPohodKeyAccepted = false; }
		
		writeln("test50");

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
		
		writeln("test60");
		auto pohodForm = getPageTemplate( pageTemplatesDir ~ "edit_pohod_form.html" );
		
		
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
		{	
			
		}
		else
		{	writeln("test70");
			создатьФормуИзмененияПохода(pohodForm, pohodRec, touristRS);
			
		}

		string content = pohodForm.getString();
		writeln("content.length", content.length);
		
		tpl.set( "content", content );
		rp ~= tpl.getString();

	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}
