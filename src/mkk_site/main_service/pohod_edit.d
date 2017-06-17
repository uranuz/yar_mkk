module mkk_site.main_service.pohod_edit;
import mkk_site.main_service.devkit;

shared static this()
{
	Service.JSON_RPCRouter.join!(moderList)(`moder.list`);
	Service.JSON_RPCRouter.join!(testMethod)(`test.testMethod`);
}

struct PohodDataToWrite
{
	size_t pohodNum; // Номер походе в базе

	// Секция "Маршрутная книжка"
	string mkkCode;
	string bookNum;
	Optional!int claimState;
	string mkkComment;

	// Секция "Поход"
	string pohodRegion;
	Optional!int tourismKind;
	string route;
	Optional!int complexity;
	Optional!int complexityElems;
	Optional!Date beginDate;
	Optional!Date finishDate;
	Optional!int progress;
	string chiefComment;

	// Секция "Группа"
	string organization;
	string partyRegion;
	Optional!size_t chiefNum;
	Optional!size_t altChiefNum;
	size_t[] partyNums;
	Optional!size_t partySize;

	// Секция "Ссылки на доп. материалы"
	string[][] extraFileLinks;

	// Список имен полей, которые были изменены при редактировании
	string[] _changedFields;
}

string изменитьДанныеПохода(HTTPContext context, Optional!size_t pohodKey)
{	
	auto rq = context.request;
	
	auto pVars = rq.bodyForm;
	auto qVars = rq.queryForm;
	
	auto dbase = getCommonDB();
	
	string[] fieldNames;
	string[] fieldValues;
	
	string[] allStringFields = strFieldNames ~ [ "chef_coment", "MKK_coment" ];
	
	SiteLoger.info( "Формируем набор строковых полей и значений", "Изменение данных похода" );
	foreach( i, fieldName; allStringFields )
	{
		if( fieldName !in pVars )
			continue;
			
		string value = pVars[fieldName];
		
		fieldNames ~= `"` ~ fieldName ~ `"` ;
		fieldValues ~= ( value.length == 0 ? "NULL" : "'" ~ PGEscapeStr(value) ~ "'" );
	}
	
	SiteLoger.info( "Формируем часть запроса для вывода перечислимых полей", "Изменение данных похода" );
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
	
	SiteLoger.info( "Формируем часть запроса для вбивания начальной и конечной даты", "Изменение данных похода" );
	import std.datetime;
	import std.conv;
	
	Optional!(Date)[2] pohodDates;
	string[2] dateParamNamePrefixes = ["begin_", "finish_"];
	
	string [6] partDatesString;
	int[6] partDatesInt;
	static immutable string[] namesDateFields = [
		"begin__year", "begin__month","begin__day","finish__year", "finish__month","finish__day"
	];

	for( size_t i = 0; i < 6; ++i )
		partDatesString[i] = pVars[namesDateFields[i]];
	
	
	if( all!( (a) => !a.length )(partDatesString[0..3]) )
	{
		pohodDates[0] = null;
	}
	else
	{
		for( size_t i = 0; i < 3; ++i )
		{
			if(!isNumeric( pVars[namesDateFields[i]]) )
				throw new Exception("Неправильный формат даты начала похода");
			partDatesInt[i] = to!int(pVars[namesDateFields[i]]);
		}
		pohodDates[0] = Date(partDatesInt[0], partDatesInt[1], partDatesInt[2]);
	}
		
	
	if( all!( (a) => !a.length )(partDatesString[4..6]) )
	{
		pohodDates[1] = null;
	}
	else
	{
		for( size_t i = 3; i < 6; ++i )
		{
			if(!isNumeric( pVars[namesDateFields[i]]) )
				throw new Exception("Неправильный формат даты завершения похода");
			partDatesInt[i] = to!int(pVars[namesDateFields[i]]);
		}
		pohodDates[1] =  Date(partDatesInt[3], partDatesInt[4], partDatesInt[5]);
	}

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
	{	if( pVars["unit"]!= "null"  && pVars["unit"].length != 0 )
		{	overalTouristCount = pVars["unit"].to!size_t;
		}
	}

	size_t[] touristKeys;
	
	SiteLoger.info( "Разбор списка туристов", "Изменение данных похода" );
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
	
	SiteLoger.info( "Создаем часть запроса для записи руководителя и его заместителя", "Изменение данных похода" );
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
	
	SiteLoger.info( "Запись автора последних изменений и даты этих изменений", "Изменение данных похода" );
	fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
	fieldValues ~= [context.user.data["user_num"], "current_timestamp"];

	import std.array, webtank.net.utils : PGEscapeStr;
	import std.json, std.string;
	import webtank.common.serialization;

	SiteLoger.info( "Запись списка ссылок на доп. материалы по походу", "Изменение данных похода" );
	auto rawLinks = pVars.get("extra_file_links", "").parseJSON.fromStdJSON!(string[][]);
	string[] processedLinks;
	URI uri;
	
	foreach( ref linkPair; rawLinks )
	{
		string uriStr = strip(linkPair[0]);
		if( !uriStr.length )
			continue;

		try
		{
			uri = URI( uriStr );
		}
		catch(Exception ex)
		{
			throw new Exception("Некорректная ссылка на доп. материалы!!!");
		}

		if( uri.scheme.length == 0 )
			uri.scheme = "http";
		processedLinks ~= PGEscapeStr(uri.toString()) ~ "><" ~ PGEscapeStr(linkPair[1]);
	}
	fieldNames ~= "links";
	fieldValues ~= "ARRAY['" ~ processedLinks.join("','") ~ "']";

	SiteLoger.info( "Формирование и выполнение запроса к БД", "Изменение данных похода" );
	string queryStr;

	import std.array : join;
	if( pohodKey.isNull )
	{
		SiteLoger.info( "Запись пользователя, добавившего поход и даты добавления", "Изменение данных похода" );

		fieldNames ~= ["registrator_num", "reg_timestamp"];
		fieldValues ~= [context.user.data["user_num"], "current_timestamp"];
		queryStr = "insert into pohod ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " );";
	}
	else
	{
		queryStr = "update pohod set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num='" ~ pohodKey.value.to!string ~ "';";
	}
	auto writeDBQueryRes = dbase.query(queryStr);
	
	SiteLoger.info( "Выполнение запроса к БД завершено", "Изменение данных похода" );

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

	SiteLoger.info( "Возврат сообщения о результате операции", "Изменение данных похода" );
	
	return message;
}