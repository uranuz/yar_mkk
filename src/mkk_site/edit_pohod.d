module mkk_site.edit_pohod;

import std.conv, std.string, std.array, std.json, std.typecons;

import mkk_site.page_devkit;

import std.algorithm.searching;

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

static immutable shortTouristFormatQueryBase =
	` select num, family_name, given_name, patronymic, birth_year from tourist `;
static immutable shortTouristFormatQueryBase_count =
	`select count(1) from tourist `; // количество найденных туристов

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
	auto queryRes_count = dbase.query(zapros_count);
	uint col_str = queryRes_count.get(0, 0, "0").to!uint;// количество строк 

	string message = `Страниц ` ~ (col_str / perPage + 1).to!string ~ `  Туристов ` ~ col_str.to!string;
	auto rs = queryRes.getRecordSet(shortTouristRecFormat);

	JSONValue[string] tmp;
	tmp[`perPage`] = perPage;
	tmp[`recordCount`] = col_str;
	tmp[`rs`] = rs.toStdJSON();
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

auto getTouristInfoByKey( size_t pohodKey )
{
	auto dbase = getCommonDB();

	auto queryRes = dbase.query(
		shortTouristFormatQueryBase ~ ` where num = ` ~ pohodKey.to!string
	);

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
	Date, "begin_date",
	Date, "finish_date",
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
	
	import mkk_site.ui.date_picker: bsPlainDatePicker;

	//Создаём компонент выбора даты начала похода
	auto beginDatePicker = bsPlainDatePicker();
	with( beginDatePicker )
	{
		dataFieldName = "begin";
		controlName = "pohod_begin_date_picker";
		nullDayText = "день";
		nullMonthText = "месяц";
		nullYearText = "год";
	}

	//Создаём компонент выбора даты завершения похода
	auto finishDatePicker = bsPlainDatePicker();
	with( finishDatePicker )
	{
		dataFieldName = "finish";
		controlName = "pohod_finish_date_picker";
		nullDayText = "день";
		nullMonthText = "месяц";
		nullYearText = "год";
	}

	//Получаем данные о датах (если режим редактирования)
	if( pohodRec )
	{	//Извлекаем данные из БД
		if( !pohodRec.isNull("begin_date") )
			beginDatePicker.date = OptionalDate( pohodRec.get!("begin_date") );
		//Если данные не получены, то компонент выбора даты будет пустым
		
		if( !pohodRec.isNull("finish_date") )
			finishDatePicker.date = OptionalDate( pohodRec.get!("finish_date") );
	}
	
	pohodForm.set( "begin_date", beginDatePicker.print() );
	pohodForm.set( "finish_date", finishDatePicker.print() );

	if( pohodRec )
	{	pohodForm.set( "chef_coment", HTMLEscapeValue( pohodRec.get!"chef_coment"("") ) );
		pohodForm.set( "MKK_coment", HTMLEscapeValue( pohodRec.get!"MKK_coment"("") ) );
	}

	import mkk_site.ui.list_control: bsListBox;
	
	//Вывод перечислимых полей
	foreach( fieldName; typeof(pohodRecFormat).filterNamesByTypes!(EnumFormat) )
	{	//Создаём экземпляр генератора выпадающего списка
		auto dropdown =  bsListBox( pohodRecFormat.getEnumFormat!(fieldName) );

		dropdown.dataFieldName = fieldName;
		dropdown.controlName = fieldName ~ `_listbox`;
		dropdown.nullText = `не задано`;

		//Задаём текущее значение
		if( pohodRec && !pohodRec.isNull(fieldName) )
			dropdown.selectedValue = pohodRec.get!(fieldName)();
		
		pohodForm.set( fieldName, dropdown.print() );
	}

	import std.meta: AliasSeq;
	//Выводим руководителя похода и его зама
	foreach( fieldName; AliasSeq!( "chef_grupp", "alt_chef" ) )
	{
		string btnText = "Редактировать";
		string recordStr = "null";

		if( pohodRec && !pohodRec.isNull( fieldName ) )
		{
			auto touristRS = getTouristInfoByKey( pohodRec.get!fieldName() );

			import std.string: join;
			if( touristRS && touristRS.length )
			{
				auto touristRec = touristRS.front;
				string[] touristInfoArr;

				foreach( i; AliasSeq!( "family_name", "given_name", "patronymic" ) )
				{
					if( !touristRec.isNull(i) )
						touristInfoArr ~= touristRec.getStr!i();
				}

				btnText = touristInfoArr.join(' ')
					~ ( touristRec.isNull("birth_year") ? null : ", " ~ touristRec.getStr!"birth_year"() ~ " г.р." );

				auto jsonRec = touristRec.toStdJSON();
				recordStr = toJSON(jsonRec);
			}
			else
			{
				btnText = "[Турист не найден]";
			}

			pohodForm.set( fieldName, printHTMLAttr( "value", pohodRec.getStr!fieldName() ) );
		}


		pohodForm.set( fieldName ~ "_text", btnText );
		pohodForm.set( fieldName ~ "_record", recordStr );
	}

	if( pohodRec )
		pohodForm.set( "unit_count", ( pohodRec.isNull("unit") ? "" : printHTMLAttr( "value", pohodRec.get!("unit") ) ) );

	//Задаём действие, чтобы при след. обращении к обработчику перейти на этап записи в БД
	pohodForm.set( "form_input_action", ` value="write"` );
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
	fieldValues ~= [context.user.data["userNum"], "current_timestamp"];

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
		fieldValues ~= [context.user.data["userNum"], "current_timestamp"];
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
		{
			auto dbase = getCommonDB();
			SiteLoger.info( `Запрашиваем данные о походе с идентификатором ` ~ pohodKey.value.text );

			auto pohodRS = dbase.query(
				`select num, kod_mkk, nomer_knigi, region_pohod, organization, region_group, vid, elem, ks, marchrut, begin_date, finish_date, chef_grupp, alt_chef, unit, prepar, stat, chef_coment, "MKK_coment", unit_neim from pohod where num=` ~ pohodKey.value.text
			).getRecordSet(pohodRecFormat);
			if( ( pohodRS !is null ) && ( pohodRS.length == 1 ) ) //Если получили одну запись -> ключ верный
			{
				pohodRec = pohodRS.front;
				SiteLoger.info( `Получены данные о походе с идентификатором ` ~ pohodKey.value.text );
			}
			else
			{
				string errorMsg = `<h3>Невозможно открыть редактирование похода. Не найден поход с номером ` ~ pohodKey.value.text ~ `</h3>`;
				SiteLoger.info( errorMsg );
				return errorMsg;
			}
		}

		string content;
		
		//Определяем выполняемое страницей действие
		if( pVars.get("action", "") == "write" )
		{
			content = изменитьДанныеПохода(context, pohodKey);
		}
		else
		{
			auto pohodForm = getPageTemplate( pageTemplatesDir ~ "edit_pohod_form.html" );
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
{
	import std.string: strip;
	auto dbase = getCommonDB;

	if( !dbase.isConnected )
		return null;
	
	auto links_QRes = dbase.query(
		`select unnest( links ) from pohod where num=` ~ pohodKey.to!string ~ `;`
	);

	string[][] result;
	
	foreach( i; 0..links_QRes.recordCount )
	{
		string linkData = strip( links_QRes.get( 0, i, null ) );
		if( !linkData.length )
			continue;
		result ~= parseExtraFileLink( linkData );
	}

	return result;
}
