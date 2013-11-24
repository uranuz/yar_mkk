module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.stdio, std.array;

import webtank.datctrl._import, webtank.db._import, webtank.net.http._import, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;

immutable thisPagePath = dynamicPath ~ "edit_pohod";
immutable authPagePath = dynamicPath ~ "auth";

static this()
{	
	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
	Router.join( new JSON_RPC_HandlingRule() );
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
auto getTouristList(string filterStr)
{	string result;
	auto dbase = getCommmonDB();
	
	if ( !dbase.isConnected )
		return null; //Завершаем

	auto queryRes = dbase.query(  
		shortTouristFormatQueryBase ~ `where family_name ILIKE '`
		~ PGEscapeStr( filterStr ) ~ `%' limit 25;`
	);
	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	return queryRes.getRecordSet(shortTouristRecFormat);
}



auto getPohodParticipants( size_t pohodNum, uint requestedLimit )
{	auto dbase = getCommmonDB();
	if ( !dbase.isConnected )
		return null; //Завершаем
	
	uint maxLimit = 25;
	uint limit = ( requestedLimit < maxLimit ? requestedLimit : maxLimit );
	
	auto queryRes = dbase.query(
		shortTouristFormatQueryBase ~ `where num=`
		~ pohodNum.to!string ~ ` limit ` ~ limit.to!string ~ `;`
	);
	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	return queryRes.getRecordSet(shortTouristRecFormat);
}

// import std.typecons, std.typetuple;
// alias TypeTuple!(
// 	string, "kod_mkk", string, "nomer_knigi", string, "region_pohod", string, "organization", string, "organization", string, "vid", string, "element", string, "ks", string, "marchrut", string, "begin_date", string, "finish_date", string, "chef_grupp", string, "alt_chef", string, "unit", string, "prepare", string, "status", string, "emitter", string, "chef_coment", string, "MKK_coment", size_t[], "unit_neim"
// ) PohodTupleType;

enum pohodEnumValues = [
	"vid": [ 1:"пешеходный", 2:"лыжный", 3:"горный", 4:"водный", 5:"велосипедный", 6:"автомото", 7:"спелео", 8:"парусрый", 9:"конный", 10:"комбинированный" ],
	"element": [ 1:"с эл.1", 2:"с эл.2", 3:"с эл.3", 4:"с эл.4", 5:"с эл.5", 6:"с эл.6" ],
	"ks": [ 10:"п.в.д.", 1:"н.к.", 1:"первая", 2:"вторая", 3:"третья", 4:"четвёртая", 5:"пятая", 6:"шестая", 11:"путешествие" ],
	"prepare": [ 1:"планируется", 2:"готовится", 3:"набор группы", 4:"набор завершон", 5:"на маршруте", 6:"пройден" ],
	"status": [ 1:"рассматривается", 2:"заявлен", 3:"на контроле", 4:"пройден", 5:"засчитан" ]
];


RecordFormat!(
	ft.IntKey, "num", ft.Str, "kod_mkk", ft.Str, "nomer_knigi", ft.Str, "region_pohod",
	ft.Str, "organization", ft.Str, "region_group", ft.Enum, "vid", ft.Enum, "element",
	ft.Enum, "ks", ft.Str, "marchrut", ft.Date, "begin_date",
	ft.Date, "finish_date", ft.Str, "chef_group", ft.Str, "alt_chef",
	ft.Int, "unit", ft.Enum, "prepare", ft.Enum, "status",
	ft.Str, "chef_coment", ft.Str, "MKK_coment", ft.Str, "unit_neim"
) pohodRecFormat = 
{	enumValues: pohodEnumValues
};

enum string[] months = [ "январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь" ];

enum strFieldNames = [ "kod_mkk", "nomer_knigi", "region_pohod", "organization", "region_group", "marchrut" ];


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
	
	//Вывод перечислимых полей
	foreach( fieldName, values; enumValueBlocks )
	{	//Создаём экземпляр генератора выпадающего списка
		auto dropdown =  new PlainDropDownList;
		
		dropdown.values = values;
		dropdown.name = fieldName;
		dropdown.id = fieldName;
		
		//Задаём текущее значение
		if( pohodRec.isNull(fieldName) )
			dropdown.currValue = pohodRec.get!(fieldName)();
			
		pohodForm.set( fieldName, dropdown.print() );
	}
	
	//Задаём действие, чтобы при след. обращении к обработчику
	//перейти на этап записи в БД
	pohodForm.set( "action", ` value="write"` );
	
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
		( context.accessTicket.isInGroup("moder") || context.accessTicket.isInGroup("admin") );
	
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
	
		auto dbase = getCommmonDB;
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
		
		auto pohodForm = getPageTemplate( pageTemplatesDir ~ "edit_pohod_form.html" );
		
		
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
		{	
			
		}
		else
		{	создатьФормуИзмененияПохода(pohodForm, pohodRec, touristRS);
			
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
