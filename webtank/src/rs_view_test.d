module webtank.full_test;

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
	RecordFormat bookRecFormat; //объявляем формат записи таблицы book
	with(FieldType) {
	bookRecFormat = RecordFormat(
	[IntKey, Str, Str, Str, Int, Bool, Bool],
	["Ключ", "Название", "Автор", "Жанр", "Цена", "Есть скидка", "Твёрдый переплёт"],
	[true, true, true, true, true, true, false], //Разрешение нулевого значения
	);
	}
	
	string connStr = "dbname=postgres host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if (dbase.isConnected) output ~= "Соединение с БД установлено";
	else  output ~= "Ошибка соединения с БД";
	
	auto response = dbase.query(`select * from book`); //запрос к БД
	auto rs = response.getRecordSet(bookRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	//import std.conv;
	//output ~= response.recordCount.to!(string);
	//writeln(response.recordCount);
	auto rsView = new RecordSetView(rs);
	with( FieldViewManner )
		rsView.viewManners = [plainText, plainText, simpleControls, plainText, plainText, simpleControls, simpleControls];
	rsView.FieldHTMLClasses = [`cod`, `book-name`, `author`];
	rsView.HTMLTableClass = `book-table`;
	rsView.outputModes.length = 7;
	with( FieldOutputMode ) 
		rsView.outputModes[0..$] = visible;
	string html = `<html><body><head><link rel="stylesheet" type="text/css" href="` ~ projectPath ~ `/css/full_test.css">` 
		~ rsView.getHTMLStr() ~ `</head></body></html>`; //превращаем RecordSet в строку html-кода
	output ~= html;
	}
	catch(Exception e) {
		output ~= "\r\nНепредвиденная ошибка в работе сервера";
	}
	finally {
		writeln(output);
	}
	return 0;
}
