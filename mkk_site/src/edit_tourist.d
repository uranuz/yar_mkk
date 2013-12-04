module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.stdio, std.utf;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.http.routing, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.net.http.context, webtank.net.http.json_rpc_routing;

import mkk_site.site_data, mkk_site.authentication, mkk_site.utils;
import std.conv, std.algorithm;

immutable thisPagePath = dynamicPath ~ "edit_tourist";
immutable authPagePath = dynamicPath ~ "auth";

shared static this()
{	Router.join( new URIHandlingRule(thisPagePath, &netMain) );
	Router.join( new JSON_RPC_HandlingRule!(тестНаличияПохожегоТуриста)() );
}

alias FieldType ft;

auto короткийФорматТурист = immutable( RecordFormat!(
	ft.IntKey, "ключ", ft.Str, "фамилия", ft.Str, "имя", ft.Str, "отчество",
		ft.Int, "годРожд"
) )();

auto тестНаличияПохожегоТуриста(
	string фамилия,
	string имя,
	string отчество,
	string годРожд  //TODO: Переделать на число
) {
	writeln("тестНаличияПохожегоТуриста");
	
	IDatabase dbase = getCommonDB();
	
	//if( !dbase || !dbase.isConnected )
		//TODO: Добавить ошибку
	
	string  запросНаличияТуриста;//запрос на наличие туриста в базе
	try {
	
	запросНаличияТуриста=`select num, family_name, given_name, patronymic, birth_year from tourist where ` 
	~ `family_name=         '`~ фамилия ~`' ` 
	~ ` and (`;
	
	if(имя.length!=0)
	{запросНаличияТуриста~= ` given_name ILIKE   '`~имя[0..имя.toUTFindex(1)]~`%' 
							OR  coalesce(given_name, '') = ''	) `;}
		else   { запросНаличияТуриста~=  ` given_name ILIKE  '%%' OR  coalesce(given_name, '') = ''	 )` ;  }           
	запросНаличияТуриста~=  ` and (`;
		
	if(отчество.length!=0) 
	{запросНаличияТуриста~= ` patronymic  ILIKE  '`~отчество[0..отчество.toUTFindex(1)]~`%' 
									OR     coalesce(patronymic, '') = '') `;}
			else   { запросНаличияТуриста~=  ` patronymic ILIKE  '%%'  OR     coalesce(patronymic, '') = '' )` ;  }                                    
		
		if( годРожд.length > 0 )
		{	try {
				запросНаличияТуриста~= ` and (birth_year = `~ годРожд.to!string 
														~ ` OR  birth_year IS NULL);`;
			} catch(std.conv.ConvException e) {}
		}
		else 
		{ запросНаличияТуриста~=  ` and birth_year IS NULL;` ;  }                                   
	}
	catch(Throwable e)
	{	writeln(e.msg);
	}

	writeln(запросНаличияТуриста);
	auto response = dbase.query(запросНаличияТуриста); //запрос к БД
		auto похожиеФИО = response.getRecordSet(короткийФорматТурист);
	
	writeln("похожиеФИО.length", похожиеФИО.length);
		
	if( похожиеФИО && похожиеФИО.length > 0  )
		return создатьТаблицуПохожихТуристов(похожиеФИО);
	else
		return null;
}

string создатьТаблицуПохожихТуристов(
	RecordSet!( typeof(короткийФорматТурист) ) похожиеФИО
) {
	string table = `<table class="tab">`;
	table ~= `<tr>`;
   table ~= `<td> Ключ</td>`;
	
	table ~=`<td>Фамилия</td><td> Имя</td><td> Отчество</td><td> год рожд.</td><td>Править</td>`;

	foreach(rec; похожиеФИО)
	{	

	   table ~= `<tr>`;
		table ~= `<td>` ~ rec.get!"ключ"(0).to!string ~ `</td>`;
		table ~= `<td>` ~ rec.get!"фамилия"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"имя"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"отчество"("")  ~ `</td>`;
		table ~= `<td>` ~ ( rec.isNull("годРожд") ? ``: rec.get!"годРожд"().to!string ) ~ `</td>`;
	   table ~= `<td> <a href="`~dynamicPath~`edit_tourist?key=`~rec.get!"ключ"(0).to!string~`">Изменить</a>  </td>`;
		
		table ~= `</tr>`;
	}
	
	table ~= `</table>`;

	return table;
}

string записатьТуриста(HTTPContext context, size_t touristKey, bool isNewTourist)
{
	auto pVars = context.request.postVars;
	
	string queryStr;
	try
	{	string fieldNamesStr;  //имена полей для записи
		string fieldValuesStr; //значения полей для записи
		
	
		//Формирование запроса для записи строковых полей в БД
		foreach( i, fieldName; strFieldNames )
		{	string value = pVars.get(fieldName, null);
			if( value.length > 0  )
			{	fieldNamesStr ~= ( ( fieldNamesStr.length > 0  ) ? ", " : "" ) ~ "\"" ~ fieldName ~ "\""; 
				fieldValuesStr ~=  ( ( fieldValuesStr.length > 0 ) ? ", " : "" ) ~ "'" ~ PGEscapeStr(value) ~ "'"; 
			}
		}
		
		//Формирование запроса на запись даты рождения туриста
		auto birthDayStr = pVars.get("birth_day", null);
		auto birthMonthStr = pVars.get("birth_month", null);
		if( (birthDayStr.length > 0) && (birthMonthStr.length >0) )
		{	auto birthDay = birthDayStr.to!ubyte;
			auto birthMonth = birthMonthStr.to!ubyte;
			if( birthDay > 0 && birthDay <= 31 && birthMonth > 0 && birthMonth <= 12 )
			{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"birth_date\"";
				fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ birthDay.to!string ~ "." ~ birthMonth.to!string ~ "'";
			}
		}
		
		//Формирование запроса на запись года рождения туриста
		auto birthYearStr = pVars.get("birth_year", null);
		if( birthYearStr.length > 0 )
		{	auto birthYear = birthYearStr.to!uint;
			fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"birth_year\"";
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ birthYear.to!string ~ "'";
		}
		
		//Логические значения
		//Показать телефон
		bool showPhone = toBool( pVars.get("show_phone", "no") );
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"show_phone\"";
		fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ ( showPhone ? "true" : "false" ) ~ "'";
		
		//Показать емэйл
		bool showEmail = toBool( pVars.get("show_email", "no") );
		fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"show_email\"";
		fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ ( showEmail ? "true" : "false" ) ~ "'";

		
		int sports_grade;
	try	{  sports_grade =  pVars.get("sports_grade", "1000").to!int; }
	catch(std.conv.ConvException e) {  sports_grade=1000;	};
					
		if (sports_grade  in спортивныйРазряд)
		{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"razr\"";
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("sports_grade", "") ~ "'";
		}
		else
			throw new std.conv.ConvException("Выражение \"" ~ pVars.get("sports_grade", "") ~ "\" не является значением типа \"спортивный разряд\"!!!");
			
		int	judge_category;					
		try	{  judge_category =  pVars.get("judge_category", "1000").to!int; }
	catch(std.conv.ConvException e) {  judge_category=1000;	};
					
		if (judge_category  in судейскаяКатегория)
		{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"sud\"";
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("judge_category", "") ~ "'";
		}
		else
			throw new std.conv.ConvException("Выражение \"" ~ pVars.get("judge_category", "") ~ "\" не является значением типа \"судейская категория\"!!!");
		
// 				size_t moderKey = postVars.get("moder", "").to!size_t;
// 				~ moderKey.to!string ~ ", "
		if( fieldNamesStr.length > 0 && fieldValuesStr.length > 0 )
		{	if( isNewTourist )
				queryStr = "insert into tourist ( " ~ fieldNamesStr ~ " ) values( " ~ fieldValuesStr ~ " );";
			else
				queryStr = "update tourist set( " ~ fieldNamesStr ~ " ) = ( " ~ fieldValuesStr ~ " ) where num='" ~ touristKey.to!string ~ "';";
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
}


