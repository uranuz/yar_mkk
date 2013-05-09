module mkk_site.full_test;

import std.stdio;

//import webtank.db.database;
import webtank.datctrl.field_type;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
//import webtank.datctrl.record_set;

import webtank.view_logic.record_set_view;

immutable(string) projectPath = `/webtank`;

int main()
{	string output = "Content-type: text/html; charset=\"utf-8\" \r\n\r\n"; //"Выхлоп" программы
	try {
	RecordFormat touristRecFormat; //объявляем формат записи таблицы book
	with(FieldType) {
	touristRecFormat = RecordFormat(
	[IntKey, Str, Str, Str, Str, Str],
	["Ключ", "Имя", "Дата рождения", "Контакты", "Комментарий"],
	//[null, null, null, null, null, null],
	[true, true, true, true, true, true] //Разрешение нулевого значения
	);
	}
	
	string connStr = "dbname=baza_MKK host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if (dbase.isConnected) output ~= "Соединение с БД установлено";
	else  output ~= "Ошибка соединения с БД";
	
	//SELECT num, femelu, neim, otchectv0, brith_date, god, adrec, telefon, tel_viz FROM turistbl;
	string queryStr = 
		`select num, (family_name||'<br>'||given_name||'<br>'||patronymic) as name, `
		`(birth_date||'<br>'||birth_year) as birth_date , exp, `
		`(case `
			`when( show_phone = true ) then phone||'<br> ' `
			`else '' `
		`end || `
		`case `
			`when( show_email = true ) then email `
			`else '' `
		`end ) as contact, `
		`comment from tourist `;
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	auto rsView = new RecordSetView(rs);
	with( FieldOutputMode )
		rsView._outputModes = [visible, visible, visible, visible, visible, visible];
	rsView._viewManner = [FieldViewManner.plainText, FieldViewManner.plainText/*, FieldViewManner.simpleControls*/];
	rsView._HTMLClasses = [`cod`, `book-name`, `author`];
	string html = `<html><body><head><link rel="stylesheet" type="text/css" href="` ~ projectPath ~ `/css/full_test.css">` 
		~ rsView.getHTMLStr() ~ `</head></body></html>`; //превращаем RecordSet в строку html-кода
	output ~= html;
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		writeln(output);
	}
	return 0;
}

