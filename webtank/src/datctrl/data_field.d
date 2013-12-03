module webtank.datctrl.data_field;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.array, std.conv, std.json;

import webtank.datctrl.field_type, webtank.datctrl.record_format;
public import webtank.datctrl.field_type : FieldType;

///Базовый и нешаблонный интерфейс данных поля
interface IBaseDataField
{	//Свойства поля
	FieldType type() @property;  //Должно возвращать тип поля данных
	size_t length() @property;   //Должно возращать количество элементов
	string name() @property;    //Должно возвращать имя поля данных
	bool isNullable() @property;   //Поле может быть пустым (null), если true
	bool isWriteable() @property;  //Возвращает true, если в поле можно записывать
	
	bool isNull(size_t index); //Должно возвращать true, если значение null
	//Получение строкового значения по индексу. Функция вернёт defaultValue,
	//если поле пустое. По-умолчанию defaultValue = null
	string getStr(size_t index, string defaultValue);
	
	JSONValue getStdJSONFormat();
	
		//Методы записи
// 	void setNull(size_t key); //Установить значение ячейки в null
// 	void isNullable(bool nullable) @property; //Установка возможности быть пустым
}

///Основной интерфейс данных поля
interface IDataField(FieldType FieldT) : IBaseDataField
{	
	alias GetFieldValueType!(FieldT) T;

// 	//Методы и свойства по работе с диапазоном
// 	ICell front() @property;
// 	bool empty() @property;
// 	void popFront();
	
	//Методы чтения данных из поля
	///Нужно проверять, пусто или нет, иначе можно получить исключение
	T get(size_t index);
 	T get(size_t index, T defaultValue);
 	
	static if( isKeyFieldType!(FieldT) )
	{	size_t getIndex(size_t key);
		size_t getKey(size_t index);
	}
	
	static if( FieldT == FieldType.Enum )
	{	EnumFormat enumFormat();
	}
}




} //static if( isDatCtrlEnabled )