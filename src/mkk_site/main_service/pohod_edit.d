module mkk_site.main_service.pohod_edit;
import mkk_site.main_service.devkit;

shared static this()
{
	Service.JSON_RPCRouter.join!(testMethod)(`test.testMethod`);
}

struct DBName { string dbName; }

struct PohodDataToWrite
{
	import webtank.common.optional: Undefable;
	import std.datetime: Date;
	Optional!size_t num; // Номер походе в базе

	// Секция "Маршрутная книжка"
	@DBName("kod_mkk") Undefable!string mkkCode; // Код МКК
	@DBName("nomer_knigi") Undefable!string bookNum; // Номер книги
	@DBName("stat") Undefable!int claimState; // Статус заявки
	@DBName("MKK_coment") Undefable!string mkkComment; // Коментарий МКК

	// Секция "Поход"
	@DBName("region_pohod") Undefable!string pohodRegion; // Регион, где проходит поход
	@DBName("vid") Undefable!int tourismKind; // Вид туризма
	@DBName("marchrut") Undefable!string route; // Нитка маршрута
	@DBName("ks") Undefable!int complexity; // Категория сложности маршрута
	@DBName("elem") Undefable!int complexityElems; // Элементы категори сложности
	@DBName("begin_date") Undefable!Date beginDate; // Дата начала похода
	@DBName("finish_date") Undefable!Date finishDate; // Дата завершения похода
	@DBName("prepar") Undefable!int progress; // Состояние прохождения маршрута
	@DBName("chef_coment") Undefable!string chiefComment; // Коментарий руководителя группы

	// Секция "Группа"
	@DBName("organization") Undefable!string organization; // Турклуб, организация, наименование коллектива, от имени которого организован поход
	@DBName("region_group") Undefable!string partyRegion; // Город, посёлок, район, область, где постояннно проживает основная часть участников похода
	@DBName("chef_grupp") Undefable!size_t chiefNum; // Идентификатор руководителя похода в БД МКК
	@DBName("alt_chef") Undefable!size_t altChiefNum; // Идентификатор заместителя  руководителя в БД МКК (при наличии заместителя)
	@DBName("unit_neim") Undefable!(size_t[]) partyNums;  // Идентификаторы участников группы в БД МКК
	@DBName("unit") Undefable!size_t partySize; // Общее число участников похода/ размер группы

	// Секция "Ссылки на доп. материалы"
	@DBName("links") Undefable!(string[][]) extraFileLinks; // Ссылки на файлы/ документы связанные с походом/ маршрутом с их наименованием
}

auto testMethod(HTTPContext ctx, PohodDataToWrite record)
{
	import std.meta: AliasSeq, Filter, staticMap;
	import std.traits: isSomeString, getUDAs;
	import std.algorithm: canFind, countUntil;
	import std.conv: to, text, ConvException;
	import std.datetime: Date;
	import std.typecons: tuple;
	import std.string: strip, join;
	import mkk_site.site_data;
	import webtank.net.utils: PGEscapeStr;

	bool isAuthorized = ctx.user.isAuthenticated && (ctx.user.isInRole("admin") || ctx.user.isInRole("moder"));
	if( !isAuthorized ) {
		//throw new Exception(`Недостаточно прав для изменения похода!!!`);
	}
	
	string[] fieldNames;
	string[] fieldValues;

	alias PohodEnums = AliasSeq!(
		tuple("claimState", статусЗаявки),
		tuple("tourismKind", видТуризма),
		tuple("complexity", категорияСложности),
		tuple("complexityElems", элементыКС),
		tuple("progress", готовностьПохода)
	);
	enum string GetFieldName(alias E) = E[0];
	enum enumFieldNames = [staticMap!(GetFieldName, PohodEnums)];

	if( record.beginDate.isSet 
		&& record.finishDate.isSet
		&& record.finishDate.value < record.beginDate.value
	) {
		throw new Exception("Дата начала похода должна быть раньше даты окончания!!!");
	}

	//SiteLoger.info( "Формируем набор строковых полей и значений", "Изменение данных похода" );
	foreach( fieldName; AliasSeq!(__traits(allMembers, PohodDataToWrite)) )
	{
		alias FieldType = typeof(__traits(getMember, record, fieldName));
		static if( isOptional!FieldType && OptionalIsUndefable!FieldType ) {
			auto field = __traits(getMember, record, fieldName);
			enum string dbFieldName = getUDAs!(__traits(getMember, record, fieldName), DBName)[0].dbName;
			if( field.isUndef )
				continue; // Поля, которые undef с нашей т.зрения не изменились
			fieldNames ~= `"` ~ dbFieldName ~ `"`;
			static if( isSomeString!( OptionalValueType!FieldType ) )
			{
				// Для строковых полей обрамляем в кавычки и экранируем для вставки в запрос к БД
				fieldValues ~= ( (field.isSet && field.length > 0)? "'" ~ PGEscapeStr(field.value) ~ "'": "NULL" );
			}
			else static if( enumFieldNames.canFind(fieldName) )
			{
				auto enumFormat = PohodEnums[enumFieldNames.countUntil(fieldName)][1];
				if( field.isSet && field.value !in enumFormat ) {
					throw new ConvException(`Выражение "` ~ field.value.text ~ `" не является значением типа "` ~ fieldName ~ `"!!!`);
				}
				fieldValues ~= field.isSet? field.text: "NULL";
			}
			else static if( is(OptionalValueType!FieldType == Date) )
			{
				fieldValues ~= field.isSet? field.toISOExtString(): "NULL";
			}
			else static if( fieldName == "extraFileLinks" )
			{
				if( field.isNull )
				{
					fieldValues ~= "NULL";
					continue;
				}

				//SiteLoger.info( "Запись списка ссылок на доп. материалы по походу", "Изменение данных похода" );
				string[] processedLinks;
				
				foreach( ref linkPair; field.value )
				{
					string uriStr = strip(linkPair[0]);
					if( !uriStr.length )
						continue;

					URI uri;
					try {
						uri = URI( uriStr );
					} catch(Exception ex) {
						throw new Exception("Некорректная ссылка на доп. материалы!!!");
					}

					if( uri.scheme.length == 0 )
						uri.scheme = "http";
					processedLinks ~= PGEscapeStr(uri.toString()) ~ "><" ~ PGEscapeStr(linkPair[1]);
				}
				fieldValues ~= "ARRAY['" ~ processedLinks.join("','") ~ "']";
			}
			else static if( ["chiefNum", "altChiefNum"].canFind(fieldName) )
			{
				if( record.partyNums.isSet && field.isSet && !record.partyNums.value.canFind(field) ) {
					throw new Exception(
						(fieldName == "chiefNum"? "Руководитель": "Заместитель руководителя") 
						~ " похода должен быть в списке участников!!!"
					);
				}
				fieldValues ~= field.isSet? field.text: "NULL";
			}
			else static if( fieldName == "partyNums" )
			{
				if( field.isNull )
				{
					fieldValues ~= "NULL";
					continue;
				}
				if( record.partySize.isSet && field.isSet && record.partySize < field.length ) {
					throw new Exception("Указанное количество участников похода меньше количества добавленных в список!!!");
				}

				string keysQueryPart = field.value.to!(string[]).join(", ");
				if( field.length )
				{
					// Если переданы номера туристов - то проверяем, что они есть в базе
					auto nonExistingNumsResult = getCommonDB().query (
						`with nums as(
							select distinct unnest(ARRAY[` ~ keysQueryPart ~ `]::integer[]) as n
						) select n from nums
						where n not in(select num from tourist)`
					);
					if( nonExistingNumsResult.fieldCount != 1 )
						throw new Exception("Ошибка при запросе существущих в БД туристах!!!");

					size_t[] nonExistentNums;
					nonExistentNums.length = nonExistingNumsResult.recordCount;
					foreach( i; 0..nonExistingNumsResult.recordCount ) {
						nonExistentNums[i] = nonExistingNumsResult.get(0, i).to!size_t;
					}
					if( nonExistentNums.length > 0 ) {
						throw new Exception("Туристы с номерами: " ~ nonExistentNums.to!string ~ " не найдены в базе данных");
					}
				}

				fieldValues ~= "ARRAY[" ~ keysQueryPart ~ "]";
			} else static if( fieldName == "partySize" ) {
				fieldValues ~= field.isSet? field.text: "NULL";
			} else {
				static assert(false, `Unprocessed Undefable field: ` ~ fieldName); // Не написан код для обработки поля Undefable
			}
		}
	}

	string dbErrorMsg;
	if( fieldNames.length > 0 )
	{
		//SiteLoger.info( "Запись автора последних изменений и даты этих изменений", "Изменение данных похода" );
		if( "user_num" !in ctx.user.data ) {
			//throw new Exception("Не удаётся определить идентификатор пользователя");
		}
		//fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
		//fieldValues ~= [ctx.user.data["user_num"], "current_timestamp"];
		//SiteLoger.info("Формирование и выполнение запроса к БД", "Изменение данных похода");
		string queryStr;

		import std.array: join;
		if( record.num.isSet )	{
			queryStr = "update pohod set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num='" ~ record.num.value.to!string ~ "';";
		}
		else
		{
			//SiteLoger.info( "Запись пользователя, добавившего поход и даты добавления", "Изменение данных похода" );

			//fieldNames ~= ["registrator_num", "reg_timestamp"];
			//fieldValues ~= [ctx.user.data["user_num"], "current_timestamp"];
			queryStr = "insert into pohod ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " );";
		}

		debug import std.stdio;
		debug writeln(`pohod write query: `, queryStr);
		auto writeDBQueryRes = getCommonDB().query(queryStr);
		dbErrorMsg = getCommonDB().lastErrorMessage;
	}

	//SiteLoger.info( "Выполнение запроса к БД завершено", "Изменение данных похода" );
/+
	string message;
	
	if( pohodKey.isNull  )
	{	if( dbErrorMsg is null )
			message = "<h3>Данные о походе успешно добавлены в базу данных!!!</h3>"
			~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
		else
			message = "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
			~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
			~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>\r\n";
	}
	else
	{	if( dbErrorMsg is null )
			message = "<h3>Данные о походе успешно обновлены!!!</h3>"
			~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ pohodKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
			~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
		else
			message = "<h3>Произошла ошибка при обновлении данных!!!</h3>"
			~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
			~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ pohodKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
			~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>\r\n";
	}
+/
	//SiteLoger.info( "Возврат сообщения о результате операции", "Изменение данных похода" );


	return record.num;
}



/+
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
+/