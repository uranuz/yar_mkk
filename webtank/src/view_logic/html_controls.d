module webtank.view_logic.html_controls;

import std.conv, std.datetime, std.array, std.stdio;

import webtank.net.utils, webtank.datctrl.record_format;

class HTMLControl
{
	string name;  ///Имя поля ввода
	string[] classes; ///Набор HTML-классов присвоенных списку
	string id;  ///HTML-идентификатор поля ввода
}

///Простенький класс для генерации HTML-разметки для выпадающего списка элементов
class PlainDropDownList: HTMLControl
{	
	///Метод генерирует разметку по заданным параметрам
	string print()
	{	
		string[string] attrs;
		
		if( name.length > 0 )
			attrs["name"] = name;
			
		if( id.length > 0 )
			attrs["id"] = id;
			
		if( classes.length > 0 )
			attrs["class"] = HTMLEscapeValue( join(classes, ` `) );
		
		string output = `<select` ~ printHTMLAttributes(attrs) ~ `>`;
		
		foreach( name, key; values )
		{	output ~= `<option value="` ~ key.to!string ~ `"`
			~ ( ( key == _currKey && !_isEmpty ) ? ` selected` : `` )
			~ `>` ~ HTMLEscapeText(name) ~ `</option>`;
		}
		
		output ~= `</select>`;
		
		return output;
	}
	
	EnumFormat values; ///Значения выпадающего списка (перечислимый тип)
	
	int currKey() @property  ///Текущее значение списка
	{	return _currKey; }
	
	void currKey(int value) @property
	{	_currKey = value;
		_isEmpty = false;
	}
	
	bool isEmpty() @property
	{	return _isEmpty; }
	
	void reset()
	{	_isEmpty = true; }

protected:
	bool _isEmpty = true;
	int _currKey;
}

enum string[] months = 
	[	"январь", "февраль", "март", 
		"апрель", "май", "июнь", 
		"июль", "август", "сентябрь", 
		"октябрь", "ноябрь", "декабрь"
	];

	
///Простой класс для создания HTML компонента выбора данных
///Состоит из двух текстовых полей (день, год) и выпадающего списка месяцев
class PlainDatePicker: HTMLControl
{	string print()
	{	
		string[string][string] attrBlocks = 
		[	`year`: null, `month`: null, `day`: null ];
		
		//Задаём базовые аттрибуты для окошечек календаря
		foreach( word, ref attrs; attrBlocks )
		{	if( name.length > 0 ) //Путсые аттрибуты не записываем
				attrs["name"] = name ~ `_` ~ word;
				
			if( id.length > 0 )
				attrs["id"] = id ~ `_` ~ word;
				
			if( classes.length > 0 )
				attrs["class"] = HTMLEscapeValue( join(classes, ` `) );
		}
		
		//Задаём доп. аттрибуты и значения для дня и месяца
		attrBlocks[`year`]["type"] = `text`;
		attrBlocks[`day`]["type"] = `text`;
		
		if( !_isEmpty )
		{	attrBlocks[`year`]["value"] = date.year.to!string;
			attrBlocks[`day`]["value"] = date.day.to!string;
		}
		
		//Собираем строки окошечек для вывода
		string yearInp = `<input` ~ printHTMLAttributes(attrBlocks[`year`]) ~ `>`;
		string dayInp = `<input` ~ printHTMLAttributes(attrBlocks[`day`]) ~ `>`;
		
		string monthInp = `<select` ~ printHTMLAttributes(attrBlocks[`month`]) ~ `>`;
		foreach( i, month; months )
		{	monthInp ~= `<option value="` ~ (i+1).to!string ~ `"`
			~ ( ( i+1 == date.month && !_isEmpty ) ? ` selected` : `` )
			~ `>` ~ month ~ `</option>`;
		}
		monthInp ~= `</select>`;
		
		return dayInp ~ ` ` ~ monthInp ~ ` ` ~ yearInp;
	}
	
	Date date() @property
	{	return _date;
	}
	
	void date(Date value) @property
	{	_date = value;
		_isEmpty = false;
	}
	
	void reset()
	{	_isEmpty = true; }

protected:
	bool _isEmpty = true;
	Date _date;
}

string printHTMLAttributes(string[string] values)
{	string result;
	foreach( attrName, attrValue; values )
	{	if( attrName.length > 0 )
			result ~= ` ` ~ attrName 
				~ ( attrValue.length > 0 ? `="` ~ HTMLEscapeValue(attrValue) ~ `"` : `` );
	}
	return result;
}

// void main()
// {	auto datePicker = new PlainDatePicker;
// // 	datePicker.name = "birth_date";
// // 	datePicker.id = "id";
// 	
// 	datePicker.date = Date(1996, 11, 20);
// 	datePicker.classes ~= "some_date";
// 	
// 	writeln(datePicker.print());
// 	
// 	auto dropdown = new PlainDropDownList;
// 	dropdown.values = [1: "первый", 2: "второй", 3: "третий"];
// 	dropdown.currValue = 2;
// 	dropdown.classes ~= ["something", "something_else"];
// 	
// 	writeln(dropdown.print());
// }