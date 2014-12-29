module mkk_site.edit_pohod;

import std.conv, std.string, std.file, std.array, std.json, std.typecons, core.thread;

import std.math;


import webtank.datctrl, webtank.db, webtank.net.http, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.view_logic.html_controls, webtank.common.optional;

// import webtank.net.javascript;

import mkk_site;
import std.stdio;

immutable(string) thisPagePath;
immutable(string) authPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "edit_pohod";
	authPagePath = dynamicPath ~ "auth";
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(getTouristList);
	JSONRPCRouter.join!(списокУчастниковПохода);
	JSONRPCRouter.join!(списокСсылокНаДопМатериалы);
	JSONRPCRouter.join!(удалитьПоход);
}

static immutable shortTouristRecFormat = RecordFormat!( 
	PrimaryKey!(int), "num", 
	string, "family_name", 
	string, "given_name", 
	string, "patronymic", 
	int, "birth_year" 
)();

immutable shortTouristFormatQueryBase = 
	` select num, family_name, given_name, patronymic, birth_year from tourist `;
immutable shortTouristFormatQueryBase_count =	
	`select count(1)  from tourist `; // количество найденных туристов

//import std.stdio;
	
void удалитьПоход(HTTPContext context, size_t pohodKey)
{
	if( !context.user.isAuthenticated )
		return;
		
	if( !context.user.isInRole("admin") )
		return;
	
	auto dbase = getCommonDB();
	
	if ( !dbase.isConnected )
		return; //Завершаем\
		
	string ЗапросУдалить= `DELETE from pohod where num=` ~ pohodKey.to!string ~ `;`;
	auto queryRes = dbase.query(ЗапросУдалить);
}


//RPC метод для вывода списка туристов (с краткой информацией) по фильтру
auto getTouristList(HTTPContext context, string фамилия, string имя, string отчество, string год_рождения, string регион, string город, string улица, string страница)
{	
	auto dbase = getCommonDB();
	
	if ( !dbase.isConnected )
		return JSONValue(null); //Завершаем
	
	JSONValue result;
	
	if( !context.user.isAuthenticated )
		return result;
		
	import std.stdio;
	int perPage = 10;
	
	string addition_zapros = ` where family_name ILIKE '`;	
	addition_zapros ~= PGEscapeStr(фамилия) ~ `%' `;

	if (имя.length > 0) 
		addition_zapros ~= ` AND given_name ILIKE '` ~ PGEscapeStr(имя) ~ `%' `;

	if ( отчество.length > 0 )
		addition_zapros ~= ` AND patronymic ILIKE '` ~ PGEscapeStr(отчество) ~ `%' `;

	if ( год_рождения.length > 0 ) 
		addition_zapros ~= ` AND  birth_year ='` ~ PGEscapeStr(год_рождения) ~ `' `; 
			
	if ( регион.length > 0 )
		addition_zapros ~= ` AND address ILIKE '%` ~ PGEscapeStr(регион) ~ `%' `; 

	if (  город.length > 0 )
		addition_zapros ~= ` AND address ILIKE '%` ~ PGEscapeStr(город) ~ `%' `; 

	if ( улица.length > 0 )
		addition_zapros ~= ` AND address ILIKE '%` ~ PGEscapeStr(улица) ~ `%' `;     

	string addition_zapros2 = ` LIMIT ` ~ perPage.to!string ~ ` `;
	if ( страница.length <= 0 || страница.to!int < 2)
		addition_zapros2 ~= ` OFFSET 0;`;
	else
		addition_zapros2 ~= ` OFFSET ` ~ (perPage*страница.to!int-perPage).to!string ~ `;`;                

	string zapros = shortTouristFormatQueryBase ~ addition_zapros ~ ` order by family_name ` ~ addition_zapros2; 
	string zapros_count = shortTouristFormatQueryBase_count ~ addition_zapros ~ `;`;

	auto queryRes = dbase.query(zapros);
	auto queryRes_count = dbase.query(zapros_count) ;
	uint col_str = queryRes_count.get(0, 0, "0").to!uint;// количество строк 
	
	string message = `Страниц ` ~ (ceil(cast(float) col_str/perPage)).to!string ~ `  Туристов ` ~ col_str.to!string;
	auto rs = queryRes.getRecordSet(shortTouristRecFormat);

	JSONValue[string] tmp;
	tmp[`perPage`] = perPage;
	tmp[`recordCount`] = col_str;
	tmp[`rs`] = rs.getStdJSON();
	result.object = tmp;
	
	return result;
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
		where num=nums.id::bigint
		order by family_name;
`	);

	if( queryRes is null || queryRes.recordCount == 0 )
		return null;
	
	return queryRes.getRecordSet(shortTouristRecFormat);
}

import std.datetime;
import std.typecons;

static immutable RecordFormat!(
	PrimaryKey!(size_t), "num", 
	string, "kod_mkk", 
	string, "nomer_knigi", 
	string, "region_pohod",
	string, "organization", 
	string, "region_group", 
	typeof(видТуризма), "vid", 
	typeof(элементыКС), "elem",
	typeof(категорияСложности), "ks", 
	string, "marchrut", 
	Date, "begin_date",//*********************************
	Date, "finish_date",//********************************* 
	size_t, "chef_grupp", 
	size_t, "alt_chef",
	int, "unit", 
	typeof(готовностьПохода), "prepar", 
	typeof(статусЗаявки), "stat",
	string, "chef_coment", 
	string, "MKK_coment", 
	string, "unit_neim"
) pohodRecFormat = typeof(pohodRecFormat)(
		null,
		tuple(
			видТуризма,
			элементыКС,
			категорияСложности,
			готовностьПохода,
			статусЗаявки
		)
	);

immutable strFieldNames = [ "kod_mkk", "nomer_knigi", "region_pohod", "organization", "region_group", "marchrut" ];

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

	//pragma(msg, "filterNamesByTypes!(EnumFormat): ", pohodRecFormat.filterNamesByTypes!(EnumFormat));
	
	import std.stdio;
	//alias pohodEnumFieldNames = 
	//Вывод перечислимых полей
	foreach( fieldName; typeof(pohodRecFormat).filterNamesByTypes!(EnumFormat) )
	{	//Создаём экземпляр генератора выпадающего списка
		auto dropdown =  listBox( pohodRecFormat.getEnumFormat!(fieldName) );

		dropdown.name = fieldName;
		dropdown.id = fieldName;

		//Задаём текущее значение
		if( pohodRec && !pohodRec.isNull(fieldName) )
			dropdown.selectedValue = pohodRec.get!(fieldName)();
		
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
			auto chefInfo_QRes = dbase.query( 
				shortTouristFormatQueryBase ~ ` where num=` ~ pohodRec.get!("chef_grupp").to!string ~ `;` 
			);
			if( chefInfo_QRes.recordCount == 1 && chefInfo_QRes.fieldCount == 5 )
			{	string chefInfoStr;
				
				foreach( i; 1..4 )
				{	if( !chefInfo_QRes.isNull( i, 0 ) )
						chefInfoStr ~= ( chefInfoStr.length == 0 ? "" : " " ) ~ chefInfo_QRes.get( i, 0 ) ;
				}
				
				chefInfoStr ~= chefInfo_QRes.isNull(4, 0) ? "" : ", " ~ chefInfo_QRes.get( 4, 0) ~ " г.р.";
				
				pohodForm.set( "chef_grupp_text", chefInfoStr );
				pohodForm.set( "chef_grupp", printHTMLAttr( "value", chefInfo_QRes.get( 0,0, "" ) ) );
			}
			else
				pohodForm.set( "chef_grupp_text", "Отсутствует в БД");
		}
		
		if( pohodRec.isNull("alt_chef") )
			pohodForm.set( "alt_chef_text", "Редактировать");
		else {
			auto chefInfo_QRes = dbase.query( 
				shortTouristFormatQueryBase ~ ` where num=` ~ pohodRec.get!("alt_chef").to!string ~ `;`
			);
			if( chefInfo_QRes.recordCount == 1 && chefInfo_QRes.fieldCount == 5 )
			{	string chefInfoStr;
				
				foreach( i; 1..4 )
				{	if( !chefInfo_QRes.isNull( i, 0 ) )
						chefInfoStr ~= ( chefInfoStr.length == 0 ? "" : " " ) ~ chefInfo_QRes.get( i, 0 );
				}
				
				chefInfoStr ~= chefInfo_QRes.isNull(4, 0) ? "" : ", " ~ chefInfo_QRes.get( 4, 0) ~ " г.р.";
				
				pohodForm.set( "alt_chef_text", chefInfoStr );
				pohodForm.set( "alt_chef", printHTMLAttr( "value", chefInfo_QRes.get( 0,0, "" ) ) );
			}
			else
				pohodForm.set( "alt_chef_text", "Отсутствует в БД");
		}
	}
	else
	{	pohodForm.set( "chef_grupp_text", "Редактировать");
		pohodForm.set( "alt_chef_text", "Редактировать");
	}

	if( pohodRec )
		pohodForm.set( "unit_count", ( pohodRec.isNull("unit") ? "" : printHTMLAttr( "value", pohodRec.get!("unit") ) ) );
	//Задаём действие, чтобы при след. обращении к обработчику
	//перейти на этап записи в БД
	pohodForm.set( "form_input_action", ` value="write"` );
}

string изменитьДанныеПохода(HTTPContext context, Optional!size_t pohodKey)
{	
	auto rq = context.request;
	
	auto pVars = rq.bodyForm;
	auto qVars = rq.queryForm;
	
	auto dbase = getCommonDB();
	
	if( !dbase.isConnected )
		throw new Exception("База данных МКК не доступна!!!");
	
	string[] fieldNames;
	string[] fieldValues;
	
	string[] allStringFields = strFieldNames ~ [ "chef_coment", "MKK_coment" ];
	
	//Формируем набор строковых полей и значений
	
	
	foreach( i, fieldName; allStringFields )
	
	{	if( fieldName !in pVars )
			continue;
			
		string value = pVars[fieldName];
		
		fieldNames ~= `"` ~ fieldName ~ `"` ;
		fieldValues ~= ( value.length == 0 ? "NULL" : "'" ~ PGEscapeStr(value) ~ "'" );
	}

	//alias pohodRecFormat.filterNamesByTypes!(EnumFormat) pohodEnumFieldNames;
	//pragma(msg, pohodRecFormat.filterNamesByTypes!(EnumFormat)[0]);
	
	//Формируем часть запроса для вывода перечислимых полей
	
	
	foreach( fieldName; typeof(pohodRecFormat).filterNamesByTypes!(EnumFormat) )
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
		
		if( !enumKey.isNull && enumKey.value !in pohodRecFormat.getEnumFormat!(fieldName) )
			throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
	
		fieldNames ~= fieldName;
		
		fieldValues ~= enumKey.isNull ? "NULL" : enumKey.value.to!string;
	}
	
	//Формируем часть запроса для вбивания начальной и конечной даты
	import std.datetime;
	
	Optional!(Date)[2] pohodDates;
	string[2] dateParamNamePrefixes = ["begin_", "finish_"];
	
	  	  
		 int [6] partDtates;
		
	    try {
	    partDtates = [(pVars["begin__year"]).to!int, (pVars["begin__month"]).to!int, (pVars["begin__day"]).to!int,
	                  (pVars["finish__year"]).to!int, (pVars["finish__month"]).to!int, (pVars["finish__day"]).to!int];
	        } 
	        catch (std.conv.ConvException exc) 
			{	throw new Exception("Введенные компоненты дат не являются числовыми значениями");
		
				//TODO: Добавить обработку исключения
			} 
	        
	       try {  
	   	pohodDates[0] =  Date(partDtates[0], partDtates[1], partDtates[2]);
		   pohodDates[1] =  Date(partDtates[3], partDtates[4], partDtates[5]);               
	           }       
	           catch (std.datetime.DateTimeException exc) 
			{	throw new Exception("Некорректный формат даты");
		
				//TODO: Добавить обработку исключения
				
			}       
		
		
		          
		          
		   writeln( pohodDates[0],"--------------",pohodDates[1]);
	


	if( !pohodDates[0].isNull && !pohodDates[1].isNull )
	{	if( pohodDates[1].value < pohodDates[0].value )
			throw new Exception("Дата начала похода должна быть раньше даты окончания");
	}
	
	foreach( i, pre; dateParamNamePrefixes )
	{	fieldNames ~= pre ~ "date";
		fieldValues ~= pohodDates[i].isNull ? "NULL" : `'` ~ pohodDates[i].value.toISOExtString() ~ `'` ;
	}

	Optional!size_t overalTouristCount;
	if( "unit" in pVars )
	{	if( pVars["unit"].length != 0 )
		{	overalTouristCount = pVars["unit"].to!size_t;
		}
	}

	size_t[] touristKeys;
	
	//Разбор списка туристов
	if( "unit_neim" in pVars )
	{	import std.array;
		
		if( pVars["unit_neim"] != "null" && pVars["unit_neim"].length != 0 )
		{	auto touristKeyStrings = std.array.split(pVars["unit_neim"], ",");
			
			foreach( keyStr; touristKeyStrings )
				touristKeys ~= keyStr.to!size_t; //Проверка на число

			if( !overalTouristCount.isNull )
			{	if( overalTouristCount.value < touristKeys.length )
					throw new Exception("Указанное количество участников похода меньше количества добавленных в список!!!");
			}
			
			auto existTouristCount_QRes = dbase.query (
				` with nums as ( select unnest( ARRAY[` ~ pVars["unit_neim"] ~ `] ) as n ) `
				~ ` select count(1) from tourist join nums on nums.n = tourist.num; `
			);
			
			if( existTouristCount_QRes.recordCount != 1 || existTouristCount_QRes.fieldCount != 1 )
				throw new Exception("Ошибка при запросе количества найденных записей о туристах!!!");
			
			size_t existTouristCount = existTouristCount_QRes.get(0, 0).to!size_t;
			if( existTouristCount != touristKeys.length )
				throw new Exception("Часть переданных в запросе ключей не соответствуют существующим в БД туристам!!!");
			
			fieldValues ~= "ARRAY[" ~ pVars["unit_neim"] ~ "]";
		}
		else
		{	fieldValues ~= "NULL";
		}
		
		fieldNames ~= "unit_neim";
	}

	if( "unit" in pVars )
	{	fieldValues ~= overalTouristCount.isNull ? "NULL" : overalTouristCount.value.to!string;
		fieldNames ~= "unit";
	}

	import std.algorithm : canFind;
	
	//Бадяжим часть запроса для записи руководителя и его заместителя
	if( "chef_grupp" in pVars )
	{	if( pVars["chef_grupp"] != "null" && pVars["chef_grupp"].length != 0 )
		{	size_t chefGruppKey = pVars["chef_grupp"].to!size_t;
			if( !touristKeys.canFind(chefGruppKey) )
				throw new Exception("Руководитель похода должен быть в списке участников!!!");
		
			fieldValues ~= chefGruppKey.to!string;
		}
		else
			fieldValues ~= "NULL";
			
		fieldNames ~= "chef_grupp";
	}
	
	if( "alt_chef" in pVars )
	{	if( pVars["alt_chef"] != "null" && pVars["alt_chef"].length != 0 )
		{	size_t chefGruppKey = pVars["alt_chef"].to!size_t;
			if( !touristKeys.canFind(chefGruppKey) )
				throw new Exception("Заместитель руководителя должен быть в списке участников!!!");
				
			fieldValues ~= chefGruppKey.to!string;
		}
		else
			fieldValues ~= "NULL";
			
		fieldNames ~= "alt_chef";
	}
	
	//Запись автора последних изменений и даты этих изменений
	fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
	fieldValues ~= [context.user.data["user_num"], "current_timestamp"];

	import std.array, webtank.net.utils : PGEscapeStr;
	import std.json, std.string;
	import webtank.common.serialization;

	//Запись списка ссылок на доп. материалы по походу
	auto rawLinks = pVars.get("extra_file_links", "").parseJSON.getDLangValue!(string[][]);
	string[] processedLinks;
	URI uri;
	
	foreach( ref linkPair; rawLinks )
	{	uri = URI( strip(linkPair[0]) );
		if( uri.scheme.length == 0 )
			uri.scheme = "http";
		processedLinks ~= PGEscapeStr(uri.toString()) ~ "><" ~ PGEscapeStr(linkPair[1]);
	}
	fieldNames ~= "links";
	fieldValues ~= "ARRAY['" ~ processedLinks.join("','") ~ "']";

	
	//Формирование и выполнение запроса к БД
	string queryStr;

	import std.array : join;
	if( pohodKey.isNull )
	{	//Запись пользователя, добавившего поход и даты добавления
		fieldNames ~= ["registrator_num", "reg_timestamp"];
		fieldValues ~= [context.user.data["user_num"], "current_timestamp"];
		queryStr = "insert into pohod ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " );";
	}
	else
	{
		queryStr = "update pohod set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num='" ~ pohodKey.value.to!string ~ "';";
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

string netMain(HTTPContext context)
{	
	auto rq = context.request;
	
	auto pVars = rq.bodyForm;
	auto qVars = rq.queryForm;
		
	bool isAuthorized = 
		context.user.isAuthenticated && 
		( context.user.isInRole("moder") || context.user.isInRole("admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаем шаблон по файлу
	
		auto dbase = getCommonDB;
		
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

		string content;
		
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
		{	content = изменитьДанныеПохода(context, pohodKey);
		}
		else
		{	auto pohodForm = getPageTemplate( pageTemplatesDir ~ "edit_pohod_form.html" );
			создатьФормуИзмененияПохода(pohodForm, pohodRec);
			content = pohodForm.getString();
		}
		
		return content;
	}
	
	
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		context.response.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return null;
	}
}

string[][] списокСсылокНаДопМатериалы(size_t pohodKey)
{	auto dbase = getCommonDB;

	if( !dbase.isConnected )
		return null;
	
	auto links_QRes = dbase.query(
		`select unnest( links ) from pohod where num=` ~ pohodKey.to!string ~ `;`
	);

	string[][] result;
	
	foreach( i; 0..links_QRes.recordCount )
		result ~= parseExtraFileLink( links_QRes.get(0, i, "") );

	return result;
}