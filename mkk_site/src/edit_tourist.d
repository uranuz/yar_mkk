module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.stdio, std.utf, std.typecons;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.http.routing, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.net.http.context, webtank.net.http.json_rpc_routing, webtank.view_logic.html_controls;

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
		запросНаличияТуриста=
			`select num, family_name, given_name, patronymic, birth_year from tourist where ` 
			~ `family_name = '`~ фамилия ~`' and (`;
		
		if( имя.length != 0 )
		{	запросНаличияТуриста ~= ` given_name ILIKE   '` ~ имя[0..имя.toUTFindex(1)] 
			~`%' OR  coalesce(given_name, '') = ''	) `;
		}
		else
		{	запросНаличияТуриста~=  ` given_name ILIKE  '%%' OR  coalesce(given_name, '') = ''	 )` ;  
		}
		запросНаличияТуриста~=  ` and (`;
			
		if( отчество.length != 0 ) 
		{	запросНаличияТуриста ~= ` patronymic  ILIKE  '` ~ отчество[0..отчество.toUTFindex(1)]
			~ `%' OR coalesce(patronymic, '') = '') `;
		}
		else
		{	запросНаличияТуриста~=  ` patronymic ILIKE  '%%'  OR  coalesce(patronymic, '') = '' )` ;
		}
		
		if( годРожд.length > 0 )
		{	try {
				запросНаличияТуриста~= ` and (birth_year = `~ годРожд.to!string 
														~ ` OR  birth_year IS NULL);`;
			} catch(std.conv.ConvException e) {}
		}
		else 
		{	запросНаличияТуриста~=  ` and birth_year IS NULL;` ;
		}
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
   table ~= `<td>Ключ</td>`;
	
	table ~=`<td>Фамилия</td><td> Имя</td><td> Отчество</td><td> год рожд.</td><td>Править</td>`;

	foreach(rec; похожиеФИО)
	{	
	   table ~= `<tr>`;
		table ~= `<td>` ~ rec.get!"ключ"(0).to!string ~ `</td>`;
		table ~= `<td>` ~ rec.get!"фамилия"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"имя"("") ~ `</td>`;
		table ~= `<td>` ~ rec.get!"отчество"("")  ~ `</td>`;
		table ~= `<td>` ~ ( rec.isNull("годРожд") ? ``: rec.get!"годРожд"().to!string ) ~ `</td>`;
	   table ~= `<td> <a href="` ~ dynamicPath ~ `edit_tourist?key=`~rec.get!"ключ"(0).to!string~`">Изменить</a>  </td>`;
		
		table ~= `</tr>`;
	}
	
	table ~= `</table>`;

	return table;
}

string показатьФормуРедактТуриста(
	IDatabase dbase,
	bool isUpdateAction,
	size_t touristKey = size_t.max
)
{	
	alias FieldType ft;
	auto touristRecFormat = RecordFormat!(
		ft.IntKey, "ключ", ft.Str, "фамилия", ft.Str, "имя", ft.Str, "отчество",
		ft.Str, "дата рожд", ft.Int, "год рожд", ft.Str, "адрес", ft.Str, "телефон",
		ft.Bool, "показать телефон", ft.Str, "эл почта", ft.Bool, "показать эл почту",
		ft.Str, "тур опыт", ft.Str, "комент", ft.Int, "спорт разряд",
		ft.Int, "суд категория"
	)();
	
	Record!( typeof(touristRecFormat) ) touristRec;
	
	//Если нам говорят, что выполняется обновление существующего туриста, то проверяем его наличие
	if( isUpdateAction )
	{	auto touristRS = dbase.query( "select num, family_name, given_name, patronymic, birth_date, birth_year, address, phone, show_phone, email, show_email, exp, comment, razr, sud from tourist where num=" ~ touristKey.to!string ~ ";" ).getRecordSet(touristRecFormat);
		if( ( touristRS !is null ) && ( touristRS.length == 1 ) ) //Если получили одну запись -> ключ верный
		{	touristRec = touristRS.front;
			isUpdateAction = true;
		}
		else
			isUpdateAction = false;
	}
	
	auto editTouristForm = getPageTemplate( pageTemplatesDir ~ "edit_tourist_form.html" );
	
	import std.string;
				
	ubyte birthDay;
	ubyte birthMonth;
	//Вывод даты рождения туриста из базы данных
	if( isUpdateAction )
	{	auto birthDateParts = split( touristRec.get!"дата рожд"(""), "." );
		if( birthDateParts.length != 2 )
			birthDateParts = split( touristRec.get!"дата рожд"(""), "," );
		if( birthDateParts.length == 2 ) 
		{	import std.conv;
			try
			{	birthDay = birthDateParts[0].to!ubyte;
				birthMonth = birthDateParts[1].to!ubyte;
			}
			catch(std.conv.Exception e)
			{ }
		}
	}
	
	//Генератор выпадающего списка месяцев
	auto monthDropdown = new PlainDropDownList;
	monthDropdown.values = месяцы.mutCopy();
	monthDropdown.name = "birth_month";
	monthDropdown.id = "birth_month";

	//Генератор выпадющего списка спорт. разрядов
	auto sportsGradeDropdown = new PlainDropDownList;
	sportsGradeDropdown.values = спортивныйРазряд.mutCopy();
	sportsGradeDropdown.name = "sports_grade";
	sportsGradeDropdown.id = "sports_grade";
	
	//Генератор выпадающего списка судейских категорий
	auto judgeCatDropdown = new PlainDropDownList;
	judgeCatDropdown.values = судейскаяКатегория.mutCopy();
	judgeCatDropdown.name = "judge_category";
	judgeCatDropdown.id = "judge_category";
	
	//Вывод данных о туристе в форму редакирования
	if( isUpdateAction )
	{	/+editTouristForm.set( "num.value", touristRec.get!"ключ"(0).to!string );+/
		editTouristForm.set(  "family_name", printHTMLAttr( `value`, touristRec.get!"фамилия"("") )  );
		editTouristForm.set(  "given_name", printHTMLAttr( `value`, touristRec.get!"имя"("") )  );
		editTouristForm.set(  "patronymic", printHTMLAttr( `value`, touristRec.get!"отчество"("") )  );
		editTouristForm.set(  "birth_year", printHTMLAttr( `value`, touristRec.getStr("год рожд", null) )  );
		editTouristForm.set(  "birth_day", printHTMLAttr( `value`, birthDay == 0 ? null : birthDay.to!string  )  );
		editTouristForm.set(  "address", printHTMLAttr( `value`, touristRec.get!"адрес"("") )  );
		editTouristForm.set(  "phone", printHTMLAttr( `value`, touristRec.get!"телефон"("") )  );
		editTouristForm.set(  "show_phone", ( touristRec.get!"показать телефон"(false) ? " checked" : "" )  );
		editTouristForm.set(  "email", printHTMLAttr( `value`, touristRec.get!"эл почта"("") ) );
		editTouristForm.set(  "show_email", ( touristRec.get!"показать эл почту"(false) ? " checked" : "" )  );
		editTouristForm.set(  "exp", printHTMLAttr( `value`, touristRec.get!"тур опыт"("") )  );
		editTouristForm.set(  "comment", HTMLEscapeText( touristRec.get!"комент"("") )  ); //textarea
		
		if( !touristRec.isNull("спорт разряд") )
			sportsGradeDropdown.currKey = touristRec.get!"спорт разряд"();
			
		if( !touristRec.isNull("суд категория") )
			judgeCatDropdown.currKey = touristRec.get!"суд категория"();
	}
	//-----------------------------------------------------------------------------------

	editTouristForm.set( "birth_month", monthDropdown.print() );
	editTouristForm.set( "sports_grade", sportsGradeDropdown.print() );
	editTouristForm.set( "judge_category", judgeCatDropdown.print() );
	
	editTouristForm.set( "action", ` value="write"` );
	
	return editTouristForm.getString();
}

string записатьТуриста(
	IDatabase dbase, 
	HTTPContext context,
	bool isUpdateAction,
	size_t touristKey = size_t.max
)
{
	auto pVars = context.request.postVars;
	
	immutable(string[]) strFieldNames = 
		[ "family_name", "given_name", "patronymic", "address", "phone", "email", "exp", "comment" ];
		
	string content;
	
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
		try { sports_grade =  pVars.get("sports_grade", "1000").to!int; }
		catch(std.conv.ConvException e) {  sports_grade=1000;	};
					
		if (sports_grade  in спортивныйРазряд)
		{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"razr\"";
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("sports_grade", "") ~ "'";
		}
		else
			throw new std.conv.ConvException("Выражение \"" ~ pVars.get("sports_grade", "") ~ "\" не является значением типа \"спортивный разряд\"!!!");
			
		int judge_category;					
		try { judge_category =  pVars.get("judge_category", "1000").to!int; }
		catch(std.conv.ConvException e) {  judge_category=1000;	};
					
		if (judge_category  in судейскаяКатегория)
		{	fieldNamesStr ~= ( fieldNamesStr.length > 0 ? ", " : "" ) ~ "\"sud\"";
			fieldValuesStr ~= ( fieldValuesStr.length > 0 ? ", " : "" ) ~ "'" ~ pVars.get("judge_category", "") ~ "'";
		}
		else
			throw new std.conv.ConvException("Выражение \"" ~ pVars.get("judge_category", "") ~ "\" не является значением типа \"судейская категория\"!!!");
		

		string queryStr;
		
		if( fieldNamesStr.length > 0 && fieldValuesStr.length > 0 )
		{	if( isUpdateAction )
				queryStr = "update tourist set( " ~ fieldNamesStr ~ " ) = ( " ~ fieldValuesStr ~ " ) where num='" ~ touristKey.to!string ~ "';";
			else
				queryStr = "insert into tourist ( " ~ fieldNamesStr ~ " ) values( " ~ fieldValuesStr ~ " );";
		}
		
		dbase.query(queryStr);
	}
	catch(std.conv.ConvException e)
	{	//TODO: Выдавать ошибку
		content = "<h3>Ошибка при разборе данных формы!!!</h3><br>\r\n";
		content ~= e.msg;
		return content;
	}
	
	if( isUpdateAction  )
	{	if( dbase.lastErrorMessage is null )
			content = "<h3>Данные о туристе успешно обновлены!!!</h3>"
			~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
			~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
		else
			content = "<h3>Произошла ошибка при обновлении данных!!!</h3>"
			~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
			~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
			~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
	}
	else
	{	if( dbase.lastErrorMessage is null )
			content = "<h3>Данные о туристе успешно добавлены в базу данных!!!</h3>"
			~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
		else
			content = "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
			~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
			~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>";
	}

	return content;
}

void netMain(HTTPContext context)
{
	auto rq = context.request;
	auto rp = context.response;
	auto ticket = context.accessTicket;
	
	auto pVars = context.request.postVars;
	auto qVars = context.request.queryVars;
	
	bool isAuthorized = 
		ticket.isAuthenticated && 
		( ticket.user.isInGroup("moder") || ticket.user.isInGroup("admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаем общий шаблон страницы
		auto tpl = getGeneralTemplate(thisPagePath);
		tpl.set("auth header message", "<i>Вход выполнен. Добро пожаловать, <b>" ~ ticket.user.name ~ "</b>!!!</i>");
		tpl.set("user login", ticket.user.login );
	
		//Создаём подключение к БД
		auto dbase = getCommonDB();
		if ( !dbase.isConnected )
		{	tpl.set( "content", "<h3>База данных МКК не доступна!</h3>" );
			rp ~= tpl.getString();
			return; //Завершаем
		}
		
		bool isTouristKeyAccepted = false; //Принят ли ключ туриста
		
		size_t touristKey;
		try {
			//Получаем ключ туриста из адресной строки
			touristKey = qVars.get("key", null).to!size_t;
			isTouristKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isTouristKeyAccepted = false; }
		
		string content;
		
		if( pVars.get("action", "") == "write" )
		{	content = записатьТуриста( dbase, context, isTouristKeyAccepted, touristKey );
			
		}
		else
		{	
			content = показатьФормуРедактТуриста( dbase, isTouristKeyAccepted, touristKey );
		}
		
		tpl.set("content", content);
		rp ~= tpl.getString();
	}
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		rp.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return;
	}
}