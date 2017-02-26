module mkk_site.edit_tourist;

import std.conv, std.string, std.utf, std.typecons;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;
static immutable(string) authPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "edit_tourist";
	authPagePath = dynamicPath ~ "auth";
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(тестНаличияПохожегоТуриста);
}

static immutable короткийФорматТурист = RecordFormat!(
	PrimaryKey!(size_t), "ключ", 
	string, "фамилия", 
	string, "имя", 
	string, "отчество",
	int, "годРожд"
)();

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
			
	запросНаличияТуриста ~= `family_name = '`~ PGEscapeStr( фамилия ) ~`' ` ;// фамилия туриста
	
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

string netMain(HTTPContext context)
{
	SiteLoger.info("netMain debug 0");
	auto rq = context.request;
	
	auto pVars = context.request.bodyForm;
	auto qVars = context.request.queryForm;
	SiteLoger.info("netMain debug 1");
	
	bool isAuthorized = 
		context.user.isAuthenticated && 
		( context.user.isInRole("moder") || context.user.isInRole("admin") );
		
	SiteLoger.info("netMain debug 2");
	
	if( isAuthorized )
	{	//Пользователь авторизован делать бесчинства
		//Создаем общий шаблон страницы
		SiteLoger.info("netMain debug 3");
		//Создаём подключение к БД
		auto dbase = getCommonDB();
		
		bool isTouristKeyAccepted = false; //Принят ли ключ туриста
		
		size_t touristKey;
		try {
			//Получаем ключ туриста из адресной строки
			touristKey = qVars.get("key", null).to!size_t;
			isTouristKeyAccepted = true;
		}
		catch(std.conv.ConvException e)
		{	isTouristKeyAccepted = false; }
		SiteLoger.info("netMain debug 4");
		
		string content;
		
		if( pVars.get("action", "") == "write" )
		{	
			bool isOk = EditTourist.writeTourist( context, isTouristKeyAccepted, touristKey );
			
			content = EditTouristView.renderWriteResult( isTouristKeyAccepted, !isOk, touristKey );
		}
		else
		{	
			SiteLoger.info("Готовимся к выводу формы туриста!");
			auto touristRec = EditTourist.getTourist(touristKey);
			
			SiteLoger.info("Запрос данных о туристе завершен!");
			
			if( touristRec )
				SiteLoger.info("Данные о туристе получены!");
			
			content = EditTouristView.renderEditForm(touristRec);
			SiteLoger.info("Вывод формы туриста завершен!");
		}
		
		SiteLoger.info("netMain debug 5");
		
		return content;
	}
	else 
	{	//Какой-то случайный аноним забрёл - отправим его на аутентификацию
		context.response.redirect( authPagePath ~ "?redirectTo=" ~ thisPagePath );
		return null;
	}
}

class EditTourist
{
public:

	static immutable touristRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "ключ", 
		string, "фамилия", 
		string, "имя", 
		string, "отчество",
		string, "дата рожд", 
		int, "год рожд",
		string, "адрес", 
		string, "телефон",
		bool, "показать телефон", 
		string, "эл почта", 
		bool, "показать эл почту",
		string, "тур опыт", 
		string, "комент", 
		typeof(спортивныйРазряд), "спорт разряд",
		typeof(судейскаяКатегория), "суд категория"
	)();

	static auto getTourist(size_t touristKey)
	{
		SiteLoger.info("getTourist 0");
		
		string touristQuery = 
`select num, family_name, given_name, patronymic, 
	birth_date, birth_year, address, phone, show_phone, email, show_email, 
	exp, comment, razr, sud from tourist where num=` ~ touristKey.text ~ `;`;
	
		SiteLoger.info("getTourist 1");
		
		auto rs = getCommonDB().query(touristQuery).getRecordSet(touristRecFormat);
		
		SiteLoger.info("getTourist 2");
		
		if( rs && rs.length == 1 )
			return rs.front;
		else
			return null;
	}
	
	static auto writeTourist(
		HTTPContext context,
		bool isUpdateAction,
		size_t touristKey = size_t.max
	)
	{
		import std.range: empty;
		
		auto pVars = context.request.bodyForm;
		
		static immutable(string[]) strFieldNames = 
			[ "family_name", "given_name", "patronymic", "address", "phone", "email", "exp", "comment" ];
			
		string[] fieldNames;  //имена полей для записи
		string[] fieldValues; //значения полей для записи
		
		//Формирование запроса для записи строковых полей в БД
		foreach( i, fieldName; strFieldNames )
		{	string value = pVars.get(fieldName, null);
			if( value.length > 0 )
			{	fieldNames ~= fieldName;
				fieldValues ~=  "'" ~ PGEscapeStr(value) ~ "'";
			}
		}

		//Формирование запроса на запись даты рождения туриста
		string birthDateStr;
		string birthDayStr = pVars.get("birth__day", null);
		string birthMonthStr = pVars.get("birth__month", null);

		bool hasBirthDay = !birthDayStr.empty && birthDayStr != "null";
		bool hasBirthMonth = !birthMonthStr.empty && birthMonthStr != "null";
		bool isNullDate = birthDayStr == "null" && birthMonthStr == "null";
		
		if( hasBirthDay || hasBirthMonth || isNullDate )
			fieldNames ~= "birth_date";
		
		if( hasBirthDay || hasBirthMonth )
		{
			if( hasBirthDay )
			{
				auto birthDay = birthDayStr.to!ubyte;
				if( birthDay > 0u && birthDay <= 31 )
					birthDateStr ~= birthDayStr;
				else
					throw new Exception("Номер дня в месяце должен быть в диапазоне от 1 до 31!!!");
			}
			
			birthDateStr ~= ".";
			
			if( hasBirthMonth )
			{	
				auto birthMonth = birthMonthStr.to!ubyte;
				if( birthMonth > 0u && birthMonth <= 12 )
					birthDateStr ~= birthMonthStr;
				else
					throw new Exception("Номер месяца должен лежать в диапазоне от 1 до 12!!!");
			}
			
			fieldValues ~= "'" ~ birthDateStr ~ "'";
		}
		else if( isNullDate ) //Если в обоих полях написано "null" - то в БД пишем null
		{
			fieldValues ~= "null";
		}

		//Формирование запроса на запись года рождения туриста
		if( auto param = pVars.get("birth__year", null) )
		{	if( !param.empty && param != "null" )
			{	auto birthYear = param.to!uint;
				fieldValues ~= "'" ~ param ~ "'";
			}
			else
				fieldValues ~= "null";

			fieldNames ~= "birth_year";
		}
		
		//Логические значения
		//Показать телефон
		bool showPhone = toBool( pVars.get("show_phone", "no") );
		fieldNames ~= "show_phone";
		fieldValues ~= "'" ~ ( showPhone ? "true" : "false" ) ~ "'";
		
		//Показать емэйл
		bool showEmail = toBool( pVars.get("show_email", "no") );
		fieldNames ~= "show_email";
		fieldValues ~= "'" ~ ( showEmail ? "true" : "false" ) ~ "'";

		if( auto param = pVars.get("razr", null) )
		{	Optional!(int) enumKey;
		
			if( !param.empty && param != "null" )
			{	try {
					enumKey = param.to!int;
				} catch (std.conv.ConvException e) {
					throw new std.conv.ConvException("Выражение \"" ~ param ~ "\" не является значением типа \"спортивный разряд\"!!!");
				}
			}
			
			if( !enumKey.isNull && enumKey !in спортивныйРазряд )
				throw new std.conv.ConvException("Выражение \"" ~ param ~ "\" не является значением типа \"спортивный разряд\"!!!");
		
			fieldNames ~= "razr";
			
			fieldValues ~= enumKey.isNull ? "null" : enumKey.value.to!string;
		}
			
		if( auto param = pVars.get("sud", null) )
		{	Optional!(int) enumKey;

			if( !param.empty && param != "null" )
			{	try {
					enumKey = param.to!int;
				} catch (std.conv.ConvException e) {
					throw new std.conv.ConvException("Выражение \"" ~ param ~ "\" не является значением типа \"судейская категория\"!!!");
				}
			}
			
			if( !enumKey.isNull && enumKey !in судейскаяКатегория )
				throw new std.conv.ConvException("Выражение \"" ~ param ~ "\" не является значением типа \"судейская категория\"!!!");
		
			fieldNames ~= "sud";
			
			fieldValues ~= enumKey.isNull ? "null" : enumKey.value.to!string;
		}

		import std.array : join;
		
		//Запись автора последних изменений и даты этих изменений
		fieldNames ~= ["last_editor_num", "last_edit_timestamp"] ;
		fieldValues ~= [context.user.data["user_num"], "current_timestamp"];
		string fieldNamesList = `"` ~ fieldNames.join(`", "`) ~ `"`;
		string fieldValuesList = fieldValues.join(", ");

		string queryStr;
		
		if( fieldNames.length > 0 && fieldValues.length > 0 )
		{	if( isUpdateAction )
			{
				queryStr = "update tourist set( " ~ fieldNamesList ~ " ) = ( " ~ fieldValuesList ~ " ) where num='" ~ touristKey.to!string ~ "';";
			}
			else
			{	fieldNames ~= ["registrator_num", "reg_timestamp"] ;
				fieldValues ~= [context.user.data["user_num"], "current_timestamp"];
				queryStr = "insert into tourist ( " ~ fieldNamesList ~ " ) values( " ~ fieldValuesList ~ " );";
			}
		}
		
		auto dbase = getCommonDB();
		dbase.query(queryStr);

		return dbase.lastErrorMessage is null;
	}
	
	
}


class EditTouristView
{
public:
	static string renderEditForm(Rec)(Rec touristRec)
	{
		import std.string;
		
		SiteLoger.info("Получаем шаблон формы редактировагия туриста");
		
		auto touristForm = getPageTemplate( pageTemplatesDir ~ "edit_tourist_form.html" );
		
		if( touristForm )
			SiteLoger.info("Шаблон формы получен");
		
		SiteLoger.info("Начало разбора данных о дате рождения туриста");

		OptionalDate birthDate;
		//Вывод даты рождения туриста из базы данных
		if( touristRec )
		{
			auto birthDateParts = split( touristRec.get!"дата рожд"(""), "." );
			if( birthDateParts.length != 2 )
				birthDateParts = split( touristRec.get!"дата рожд"(""), "," );
			if( birthDateParts.length == 2 ) 
			{	import std.conv;
				
				try {
					if( birthDateParts[0].length != 0 )
						birthDate.day = birthDateParts[0].to!ubyte;
					if( birthDateParts[1].length != 0 )
						birthDate.month = birthDateParts[1].to!ubyte;
				} catch(std.conv.ConvException e) {}
			}

			if( !touristRec.isNull("год рожд") )
				birthDate.year = touristRec.get!"год рожд"();
		}


		SiteLoger.info("Разбор данных о дате рождения завершен");
		
		import mkk_site.ui.list_control;
		import mkk_site.ui.date_picker;
		
		SiteLoger.info("Создание компонентов вывода перечислимых типов");
		//Генератор компонента выбора даты рождения
		auto birthDatePicker = bsPlainDatePicker();
		with( birthDatePicker )
		{
			dataFieldName = "birth";
			controlName = "birth_date";
			nullDayText = "день";
			nullMonthText = "месяц";
			nullYearText = "год";
		}

		//Генератор выпадющего списка спорт. разрядов
		auto sportsGradeDropdown = bsListBox(спортивныйРазряд);
		with( sportsGradeDropdown )
		{
			dataFieldName = "razr";
			controlName = "sports_grade_edit";
			nullText = "не задано";
		}

		
		//Генератор выпадающего списка судейских категорий
		auto judgeCatDropdown = bsListBox(судейскаяКатегория);
		with( judgeCatDropdown )
		{
			dataFieldName = "sud";
			controlName = "judge_category_edit";
			nullText = "не задано";
		}
		
		SiteLoger.info("Компонентов вывода перечислимых типов созданы");
		
		//Вывод данных о туристе в форму редакирования
		if( touristRec )
		{	
			SiteLoger.info("Начало вывода данных о туристе");
			SiteLoger.info("Начало вывода простых полей");
			
			/+touristForm.set( "num.value", touristRec.get!"ключ"(0).to!string );+/
			touristForm.set(  "family_name", printHTMLAttr( `value`, touristRec.get!"фамилия"("") )  );
			touristForm.set(  "given_name", printHTMLAttr( `value`, touristRec.get!"имя"("") )  );
			touristForm.set(  "patronymic", printHTMLAttr( `value`, touristRec.get!"отчество"("") )  );
			touristForm.set(  "address", printHTMLAttr( `value`, touristRec.get!"адрес"("") )  );
			touristForm.set(  "phone", printHTMLAttr( `value`, touristRec.get!"телефон"("") )  );
			touristForm.set(  "show_phone", ( touristRec.get!"показать телефон"(false) ? " checked" : "" )  );
			touristForm.set(  "email", printHTMLAttr( `value`, touristRec.get!"эл почта"("") ) );
			touristForm.set(  "show_email", ( touristRec.get!"показать эл почту"(false) ? " checked" : "" )  );
			touristForm.set(  "exp", printHTMLAttr( `value`, touristRec.get!"тур опыт"("") )  );
			touristForm.set(  "comment", HTMLEscapeText( touristRec.get!"комент"("") )  ); //textarea
			
			SiteLoger.info("Вывод простых полей завершен");
			
			SiteLoger.info("Заполнение данными перечислимых полей");
			birthDatePicker.date = birthDate;
			
			if( !touristRec.isNull("спорт разряд") )
				sportsGradeDropdown.selectedValue = touristRec.get!"спорт разряд"();
				
			if( !touristRec.isNull("суд категория") )
				judgeCatDropdown.selectedValue = touristRec.get!"суд категория"();
			SiteLoger.info("...завершено");
		}
		
		SiteLoger.info("Начало вывода контролов перечислимых типов");

		touristForm.set( "birth_date_picker", birthDatePicker.print() );
		touristForm.set( "razr", sportsGradeDropdown.print() );
		touristForm.set( "sud", judgeCatDropdown.print() );
		SiteLoger.info("...завершено");
		
		touristForm.set( "action", ` value="write"` );
		
		
		SiteLoger.info("Формирование формы редактирования туриста завершено");
		
		return touristForm.getString();
	}
	
	static auto renderWriteResult( bool isUpdateAction, bool hasError, size_t touristKey )
	{
		import std.array: appender;
		
		auto content = appender!string();
		
		if( isUpdateAction  )
		{	if( hasError )
				content ~= "<h3>Произошла ошибка при обновлении данных!!!</h3>"
				~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
				~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
				~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
			else
				content ~= "<h3>Данные о туристе успешно обновлены!!!</h3>"
				~ "Вы можете <a href=\"" ~ thisPagePath ~ "?key=" ~ touristKey.to!string ~ "\">продолжить редактирование</a> этой же записи<br>\r\n"
				~ "или перейти <a href=\"" ~ dynamicPath ~ "show_tourist\">к списку туристов</a>";
				
		}
		else
		{	if( hasError )
				content ~= "<h3>Произошла ошибка при добавлении данных в базу данных!!!</h3>"
				~ "Если эта ошибка повторяется, обратитесь к администратору сайта.<br>\r\n"
				~ "Однако вы можете <a href=\"" ~ thisPagePath ~ "\">попробовать ещё раз...</a>";
			else
				content ~= "<h3>Данные о туристе успешно добавлены в базу данных!!!</h3>"
				~ "<a href=\"" ~ thisPagePath ~ "\">Добавить ещё...</a>";
		}
		
		return content.data();
	}
}