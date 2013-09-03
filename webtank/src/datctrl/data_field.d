module webtank.datctrl.data_field;

import std.array, std.conv;

import webtank.datctrl.field_type;
public import webtank.datctrl.field_type : FieldType;

///Основной интерфейс поля данных
interface IField(FieldType FieldT)
{	
	alias GetFieldValueType!(FieldT) T;


	//Свойства поля
	FieldType type() @property;  //Должно возвращать тип поля данных
	size_t length() @property;   //Должно возращать количество элементов
	string name() @property;    //Должно возвращать имя поля данных
	bool isNullable() @property;   //Поле может быть пустым (null), если true
	bool isWriteable() @property;  //Возвращает true, если в поле можно записывать
	
// 	//Методы и свойства по работе с диапазоном
// 	ICell front() @property;
// 	bool empty() @property;
// 	void popFront();
	
	//Методы чтения данных из поля
	///Нужно проверять, пусто или нет, иначе можно получить исключение
	bool isNull(size_t index); //Должно возвращать true, если значение null
	T get(size_t index);
 	T get(size_t index, T defaultValue);
 	
	string getStr(size_t index, string  defaultValue);
	
	static if( FieldT == FieldType.IntKey )
	{	size_t getIndex(size_t key);
		size_t getKey(size_t index);
	}
	
// 	size_t _frontKey() @property;
	
	//Методы записи
// 	void setNull(size_t key); //Установить значение ячейки в null
// 	void isNullable(bool nullable) @property; //Установка возможности быть пустым

}
