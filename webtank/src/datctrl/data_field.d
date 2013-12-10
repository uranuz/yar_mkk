module webtank.datctrl.data_field;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.array, std.conv, std.json, std.datetime;

import   webtank.datctrl.record_format;

enum FieldType { Str, Int, Bool, IntKey, Date, Enum, Text };

///Строковые значения, которые трактуются как true при преобразовании
///типов. Любые другие трактуются как true
immutable(string[]) _logicTrueValues = 
		 [`true`, `t`, `yes`, `y`, `on`, `истина`, `и`, `да`, `д`];
		 
immutable(string[]) _logicFalseValues = 
		 [`false`, `f`, `no`, `n`, `off`, `ложь`, `л`, `нет`, `н`];

///Строка ошибки времени компиляции - что, мол, облом
immutable(string) _notImplementedErrorMsg = `This conversion is not implemented: `;

///Шаблон для получения реального типа поля по перечислимому 
///значению семантического типа поля
template DataFieldValueType(FieldType FieldT) 
{	static if( FieldT == FieldType.Int || FieldT == FieldType.Enum )
		alias int DataFieldValueType;
	else static if( FieldT == FieldType.Str )
		alias string DataFieldValueType;
	else static if( FieldT == FieldType.Bool )
		alias bool DataFieldValueType;
	else static if( FieldT == FieldType.IntKey )
		alias size_t DataFieldValueType;
	else static if( FieldT == FieldType.Date )
		alias std.datetime.Date DataFieldValueType;
	else
		static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
}

///Преобразование из различных настоящих типов в другой реальный
///тип, который соотвествует семантическому типу поля, 
///указанному в параметре шаблона FieldT
auto fldConv(FieldType FieldT, S)( S value )
{	
	import std.traits;
// 	// целые числа --> DataFieldValueType!(FieldT)
// 	static if( isIntegral!(S) )
// 	{	with( FieldType ) {
// 		//Стандартное преобразование
// 		static if( FieldT == Int || FieldT == Str || FieldT == IntKey )
// 		{	return value.to!( DataFieldValueType!FieldT ); }
// 		else static if( FieldT == Bool ) //Для уверенности
// 		{	return ( value == 0 ) ? false : true ; }
// 		else
// 			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
// 		}  //with( FieldType )
// 		assert(0);
// 	}
	
	// строки --> DataFieldValueType!(FieldT)
	//else 
	static if( isSomeString!(S) )
	{	with( FieldType ) {
		//Стандартное преобразование
		static if( FieldT == Int || FieldT == Str || FieldT == IntKey || FieldT == Enum )
		{	return value.to!( DataFieldValueType!FieldT ); }
		else static if( FieldT == Bool )
		{	import std.string;
			foreach(logVal; _logicTrueValues) 
				if ( logVal == toLower( strip( value ) ) ) 
					return true;
			
			foreach(logVal; _logicFalseValues) 
				if ( logVal == toLower( strip( value ) ) ) 
					return false;
			
			//TODO: Посмотреть, что делать с типами исключений в этом модуле
			throw new Exception( `Value "` ~ value.to!string ~ `" cannot be interpreted as boolean!!!` );
		}
		else static if( FieldT == Date )
		{	return std.datetime.Date.fromISOExtString(value); }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// bool --> DataFieldValueType!(FieldT)
// 	else static if( is( S : bool ) )
// 	{	with( FieldType ) {
// 		static if( FieldT == Int || FieldT == IntKey || FieldT == Enum )
// 		{	return ( value ) ? 1 : 0; }
// 		else static if( FieldT == Str )
// 		{	return ( value ) ? "да" : "нет"; }
// 		else static if( FieldT == Bool )
// 		{	return value; }
// 		else
// 			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
// 		}  //with( FieldType )
// 		assert(0);
// 	}

}

//Возвращает true если данный тип поля является типом ключевого поля
template isKeyFieldType(FieldType fieldType)
{	static if( fieldType == FieldType.IntKey )
		enum isKeyFieldType = true;
	else
		enum isKeyFieldType = false;
}

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
	alias DataFieldValueType!(FieldT) T;

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