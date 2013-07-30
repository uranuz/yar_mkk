module webtank.datctrl.data_cell;
/** Модуль содержит описание класса ячейки данных.
 *
 *  На текущий момент класс работает как ссылка на определённый элемент из поля
 *  данных, позволяя читать данные из поля с преобразованием в один из 
 *  предопределённых типов, записывать в поле, проверять заполена ли ячека  и т.д.
 */

//import std.stdio;

import std.array;
import std.conv;

import webtank.datctrl.field_type;
import webtank.datctrl.data_field;

//TODO: Подумать, нужен ли вообще этот модуль в его текущем качестве

interface ICell  ///Интерфейс ячейки
{	
	FieldType type() @property;

	///Преобразование ячейки в один из типов
	//   Фактически получение значения ячейки нужного типа
	int getInt();
	string getStr();
	bool getBool();
	
	int getInt(int defaultValue);
	string getStr(string defaultValue);
	bool getBool(bool defaultValue);
	
	bool isNull() @property;   //Вернёт true, если значение отсутствует; иначе false
	bool isNullable() @property;  //Вернёт true, если разрешено отсутствие значения; иначе false
	bool isWriteable() @property;  //Вернёт true, если разрешена запись в ячейку
	
	///Операторы присваивания ячейке
	void opAssign( int value );
	void opAssign( string value );
	void opAssign( bool value );
	
	void setNull();  //Делает ячейку пустой, если разрешено null-значение
	void isNullable(bool isNullable) @property;  //Установить разрешение на установку пустого значения
	//alias IReadableCell.isWriteable isWriteable;
}

class Cell: ICell ///Класс Ячейка
{
//В классе KeyCell реализованы операции чтения. Будем наследовать их оттуда
protected:
	IField _field; //С этим полем работаем (по ссылке)
	size_t _key; //Номер строки в поле

public:
	this( IField field, size_t key )
	{	_field = field; _key = key; }
	
	override {
		FieldType type() @property
		{	return _field.type; }
		bool isNull()
		{	return _field.isNull(_key); }
		bool isNullable() @property
		{	return _field.isNullable; }
		bool isWriteable() @property
		{	return _field.isWriteable; }

		int getInt()
		{	return _field.getInt(_key); }
		string getStr()
		{	return _field.getStr(_key); }
		bool getBool()
		{	return _field.getBool(_key); }
		
		int getInt(int defaultValue)
		{	return _field.getInt(_key, defaultValue); }
		string getStr(string defaultValue)
		{	return _field.getStr(_key, defaultValue); }
		bool getBool(bool defaultValue)
		{	return _field.getBool(_key, defaultValue); }
		
		void setNull()
		{	( cast(IField) _field ).setNull(_key); 
		}
		void isNullable(bool nullable) @property
		{	return ( cast(IField) _field ).isNullable = nullable; 
		}
		
		void opAssign( string value )
		{	( cast(IField) _field )[_key] = value;
		}
		void opAssign( int value )
		{	( cast(IField) _field )[_key] = value;
		}
		void opAssign( bool value )
		{	( cast(IField) _field )[_key] = value;
		}
	}

}