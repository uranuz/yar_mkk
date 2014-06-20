module mkk_site.edit_tourist;

import std.conv, std.string, std.file, std.utf, std.typecons;

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.database, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.datctrl.record_set, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv, webtank.net.http.context, webtank.net.http.json_rpc_handler, webtank.view_logic.html_controls, webtank.common.optional;

import mkk_site;
import std.conv, std.algorithm;

immutable(string) thisPagePath;
immutable(string) authPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "edit_tourist";
	authPagePath = dynamicPath ~ "auth";
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(тестНаличияПохожегоТуриста);
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
	Optional!(int) годРожд
) {
	IDatabase dbase = getCommonDB();
	
	//if( !dbase || !dbase.isConnected )
		//TODO: Добавить ошибку
	
	//запрос на наличие туриста в базе
	string запросНаличияТуриста = `select num, family_name, given_name, patronymic, birth_year from tourist where `;
			
	запросНаличияТуриста ~= `family_name = '`~ фамилия ~`' ` ;// фамилия туриста
	
	if( имя.length != 0 )// если набираются имя или первая буква имени туриста
	{	запросНаличияТуриста ~= ` and (`;
		запросНаличияТуриста ~= ` given_name ILIKE   '`
		~ имя[0..имя.toUTFindex(1)] //выводим имена с совпадающей первой буквой
		~`%' OR  coalesce(given_name, '') = ''	) `;// или тех у кго имя не известно
	}
		
		
	if( отчество.length > 0 ) // если набираются отчествоили первая буква отчества туриста
	{	// далее аналогично именам
	
		запросНаличияТуриста~=  ` and (`;
		запросНаличияТуриста ~= ` patronymic  ILIKE  '` ~ отчество[0..отчество.toUTFindex(1)]
		~ `%' OR coalesce(patronymic, '') = '') `;
	}

	if( !годРожд.isNull )
	{	запросНаличияТуриста~= ` and (birth_year = `~ годРожд.to!string ~ ` OR  birth_year IS NULL);`;
	}

	auto response = dbase.query(запросНаличияТуриста); //запрос к БД
		auto похожиеФИО = response.getRecordSet(короткийФорматТурист);
		
	if( похожиеФИО && похожиеФИО.length > 0  )
		return создатьТаблицуПохожихТуристов(похожиеФИО);
	else
		return null;
}

string создатьТаблицуПохожихТуристов(
	RecordSet!( typeof(короткийФорматТурист) ) похожиеФИО
) {
	string table = `<table>`;
	table ~= `<tr>`;
   table ~= `<td>Ключ</td>`;
	
	table ~=`<td>Фамилия</td><td>Имя</td><td>Отчество</td><td>Год рожд.</td><td>Правка</td>`;

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
				
	Nullable!(ubyte) birthDay;
	Nullable!(ubyte) birthMonth;
	//Вывод даты рождения туриста из базы данных
	if( isUpdateAction )
	{	auto birthDateParts = split( touristRec.get!"дата рожд"(""), "." );
		if( birthDateParts.length != 2 )
			birthDateParts = split( touristRec.get!"дата рожд"(""), "," );
		if( birthDateParts.length == 2 ) 
		{	import std.conv;
			
			try {
				if( birthDateParts[0].length != 0 )
					birthDay = birthDateParts[0].to!ubyte;
				if( birthDateParts[1].length != 0 )
					birthMonth = birthDateParts[1].to!ubyte;
			} catch(std.conv.ConvException e) {
				birthDay.nullify();
				birthMonth.nullify();
			}
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
	sportsGradeDropdown.name = "razr";
	sportsGradeDropdown.id = "razr";
	
	//Генератор выпадающего списка судейских категорий
	auto judgeCatDropdown = new PlainDropDownList;
	judgeCatDropdown.values = судейскаяКатегория.mutCopy();
	judgeCatDropdown.name = "sud";
	judgeCatDropdown.id = "sud";
	
	//Вывод данных о туристе в форму редакирования
	if( isUpdateAction )
	{	/+editTouristForm.set( "num.value", touristRec.get!"ключ"(0).to!string );+/
		editTouristForm.set(  "family_name", printHTMLAttr( `value`, touristRec.get!"фамилия"("") )  );
		editTouristForm.set(  "given_name", printHTMLAttr( `value`, touristRec.get!"имя"("") )  );
		editTouristForm.set(  "patronymic", printHTMLAttr( `value`, touristRec.get!"отчество"("") )  );
		editTouristForm.set(  "birth_year", printHTMLAttr( `value`, touristRec.getStr("год рожд", null) )  );
		editTouristForm.set(  "birth_day", printHTMLAttr( `value`, birthDay.isNull() ? null : birthDay.to!string  )  );
		editTouristForm.set(  "address", printHTMLAttr( `value`, touristRec.get!"адрес"("") )  );
		editTouristForm.set(  "phone", printHTMLAttr( `value`, touristRec.get!"телефон"("") )  );
		editTouristForm.set(  "show_phone", ( touristRec.get!"показать телефон"(false) ? " checked" : "" )  );
		editTouristForm.set(  "email", printHTMLAttr( `value`, touristRec.get!"эл почта"("") ) );
		editTouristForm.set(  "show_email", ( touristRec.get!"показать эл почту"(false) ? " checked" : "" )  );
		editTouristForm.set(  "exp", printHTMLAttr( `value`, touristRec.get!"тур опыт"("") )  );
		editTouristForm.set(  "comment", HTMLEscapeText( touristRec.get!"комент"("") )  ); //textarea
		
		if( !birthMonth.isNull() )
			monthDropdown.currKey = birthMonth.get();
		
		if( !touristRec.isNull("спорт разряд") )
			sportsGradeDropdown.currKey = touristRec.get!"спорт разряд"();
			
		if( !touristRec.isNull("суд категория") )
			judgeCatDropdown.currKey = touristRec.get!"суд категория"();
	}
	//-----------------------------------------------------------------------------------

	editTouristForm.set( "birth_month", monthDropdown.print() );
	editTouristForm.set( "razr", sportsGradeDropdown.print() );
	editTouristForm.set( "sud", judgeCatDropdown.print() );
	
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
	auto pVars = context.request.bodyForm;
	
	immutable(string[]) strFieldNames = 
		[ "family_name", "given_name", "patronymic", "address", "phone", "email", "exp", "comment" ];
		
	string content;
	
	try
	{	string[] fieldNames;  //имена полей для записи
		string[] fieldValues; //значения полей для записи
		
		//Формирование запроса для записи строковых полей в БД
		foreach( i, fieldName; strFieldNames )
		{	string value = pVars.get(fieldName, null);
			if( value.length > 0 )
			{	fieldNames ~= "\"" ~ fieldName ~ "\"";
				fieldValues ~=  "'" ~ PGEscapeStr(value) ~ "'";
			}
		}

		//Формирование запроса на запись даты рождения туриста
		if( "birth_day" in pVars || "birth_month" in pVars )
		{	string birthDateStr;
			if( "birth_day" in pVars )
			{	if( pVars["birth_day"].length != 0 && pVars["birth_day"] != "null" )
				{	auto birthDay = pVars["birth_day"].to!ubyte;
					if( birthDay > 0u && birthDay <= 31 )
						birthDateStr ~= birthDay.to!string;
					else
						throw new Exception("Номер дня в месяце должен быть в диапазоне от 1 до 31!!!");
				}
			}

			birthDateStr ~= ".";

			if( "birth_month" in pVars )
			{	if( pVars["birth_month"].length != 0 && pVars["birth_month"] != "null" )
				{	auto birthMonth = pVars["birth_month"].to!ubyte;
					if( birthMonth > 0u && birthMonth <= 12 )
						birthDateStr ~= birthMonth.to!string;
					else
						throw new Exception("Номер месяца должен лежать в диапазоне от 1 до 12!!!");
				}
			}

			fieldNames ~= "\"birth_date\"";
			fieldValues ~= "'" ~ birthDateStr ~ "'";
		}

		//Формирование запроса на запись года рождения туриста
		if( "birth_year" in pVars )
		{	if( pVars["birth_year"].length != 0 && pVars["birth_year"] != "null" )
			{	auto birthYear = pVars["birth_year"].to!uint;
				fieldValues ~= "'" ~ birthYear.to!string ~ "'";
			}
			else
				fieldValues ~= "NULL";

			fieldNames ~= "\"birth_year\"";
		}
		
		//Логические значения
		//Показать телефон
		bool showPhone = toBool( pVars.get("show_phone", "no") );
		fieldNames ~= "\"show_phone\"";
		fieldValues ~= "'" ~ ( showPhone ? "true" : "false" ) ~ "'";
		
		//Показать емэйл
		bool showEmail = toBool( pVars.get("show_email", "no") );
		fieldNames ~= "\"show_email\"";
		fieldValues ~= "'" ~ ( showEmail ? "true" : "false" ) ~ "'";

		if( "razr" in pVars )
		{	Optional!(int) enumKey;
		
			string strKey = pVars["razr"];
			if( strKey.length != 0 && toLower(strKey) != "null" )
			{	try {
					enumKey = strKey.to!int;
				} catch (std.conv.ConvException e) {
					throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"спортивный разряд\"!!!");
				}
			}
			
			if( !enumKey.isNull && enumKey !in спортивныйРазряд )
				throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"спортивный разряд\"!!!");
		
			fieldNames ~= `"razr"`;
			
			fieldValues ~= enumKey.isNull ? "NULL" : enumKey.value.to!string;
		}
			
		if( "sud" in pVars )
		{	Optional!(int) enumKey;
		
			string strKey = pVars["sud"];
			if( strKey.length != 0 && toLower(strKey) != "null" )
			{	try {
					enumKey = strKey.to!int;
				} catch (std.conv.ConvException e) {
					throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"судейская категория\"!!!");
				}
			}
			
			if( !enumKey.isNull && enumKey !in спортивныйРазряд )
				throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"судейская категория\"!!!");
		
			fieldNames ~= `"sud"`;
			
			fieldValues ~= enumKey.isNull ? "NULL" : enumKey.value.to!string;
		}

		import std.array : join;
		
		//Запись автора последних изменений и даты этих изменений
		fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
		fieldValues ~= [context.user.data["user_num"], "current_timestamp"];

		string queryStr;
		
		if( fieldNames.length > 0 && fieldValues.length > 0 )
		{	if( isUpdateAction )
				queryStr = "update tourist set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num='" ~ touristKey.to!string ~ "';";
			else
			{	fieldNames ~= ["registrator_num", "reg_timestamp"] ;
				fieldValues ~= [context.user.data["user_num"], "current_timestamp"];
				queryStr = "insert into tourist ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " );";
			}
		}
		
		dbase.query(queryStr);
	}
	catch(Throwable e)
	{	//TODO: Выдавать ошибку
		content = "<h3>Ошибка при разборе данных формы!!!</h3><br>\r\n";
		//content ~= e.msg;
		content ~= e.to!string;
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
	auto user = context.user;
	
	auto pVars = context.request.bodyForm;
	auto qVars = context.request.queryForm;
	
	bool isAuthorized = 
		user.isAuthenticated && 
		( user.isInRole("moder") || user.isInRole("admin") );
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаем общий шаблон страницы
		auto tpl = getGeneralTemplate(context);
	
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
