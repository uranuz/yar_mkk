module webtank.datctrl.data_field;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.array, std.conv;

import webtank.datctrl.field_type;
public import webtank.datctrl.field_type : FieldType;

///Базовый и нешаблонный интерфейс поля данных
interface IBaseField
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
	
		//Методы записи
// 	void setNull(size_t key); //Установить значение ячейки в null
// 	void isNullable(bool nullable) @property; //Установка возможности быть пустым
}

///Основной интерфейс поля данных
interface IField(FieldType FieldT) : IBaseField
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
 	

	static if( FieldT == FieldType.IntKey )
	{	size_t getIndex(size_t key);
		size_t getKey(size_t index);
	}

}


} //static if( isDatCtrlEnabled )