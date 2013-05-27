module webtank.datctrl.data_field;

import std.array;
import std.conv;

//import std.stdio;

import webtank.datctrl.field_type;
public import webtank.datctrl.field_type : FieldType;
import webtank.datctrl.data_cell;

///Основной интерфейс поля данных
interface IField
{	//Свойства поля
	FieldType type() @property;  //Должно возвращать тип поля данных
	size_t length() @property;   //Должно возращать количество элементов
	string name() @property;    //Должно возвращать имя поля данных
	bool isNullable() @property;   //Поле может быть пустым (null), если true
	bool isWriteable() @property;  //Возвращает true, если в поле можно записывать
	
	//Методы и свойства по работе с диапазоном
	ICell front() @property;
	bool empty() @property;
	void popFront();
	
	//Методы чтения данных из поля
	bool isNull(size_t key); //Должно возвращать true, если значение null
	ICell opIndex(size_t key);
	//long getLong(size_t key);
	int getInt(size_t key);
	string getStr(size_t key);
	bool getBool(size_t key);
	
	size_t _frontKey() @property;
	
	//Методы записи
	void setNull(size_t key); //Установить значение ячейки в null
	void isNullable(bool nullable) @property; //Установка возможности быть пустым

	void opIndexAssign(int value, size_t key);
	void opIndexAssign(string value, size_t key);
	void opIndexAssign(bool value, size_t key);
}

interface IFieldFormat //Интерфейс формата поля
{	string name() @property;
	FieldType type() @property;
	bool isNullable() @property;
	bool isWriteable() @property;
	IField linkField() @property;
}

///Класс ключевого поля
class KeyField : IField
{
protected:
	size_t[size_t] _indexes;
	immutable string _name;
	size_t _iter = 0; //Итератор, который проходит по всем ключам массива индексов
	size_t[] _keys;   //Массив ключей

public:
	this( string name )
	{	_name = name; }
	
	override { //Переопределяем интерфейсные методы
		FieldType type()
		{	return FieldType.IntKey; }
		size_t length()
		{	return _indexes.length; }
		string name() @property
		{	return _name; }
		
		bool isNullable() @property
		{	return false; }
		bool isWriteable() @property
		{	return false; }
		bool isNull(size_t key)
		{	if( key in _indexes ) return false; 
			return true;
		}
		
		//Методы и свойства по работе с диапазоном
		ICell front() @property
		{	if( _iter < _keys.length )
				return new Cell( this, _keys[_iter]  );
			assert(0, "Выход за границы дипазона") ;
		}
		bool empty() @property
		{	if ( _iter >= _indexes.length )
			{	_iter = 0;
				return true; 
			}
			else return false;
		}
		void popFront()
		{	_iter++; 
		}
		
		ICell opIndex(size_t key)  
		{	if( keyExists(key) )
				return new Cell( this, key );
			else return null;
		}

		int getInt(size_t key)
		{	if( keyExists(key) ) 
				return fldConv!( FieldType.Int )( key ); 
			assert(0);
		}
		string getStr(size_t key)
		{	if( keyExists(key) ) 
				return fldConv!( FieldType.Str )( key ); 
			assert(0);
		}
		bool getBool(size_t key)
		{	if( keyExists(key) ) 
				return fldConv!( FieldType.Bool )( key ); 
			assert(0);
		}
		
		void setNull(size_t key) //Установить значение ячейки в null
		{	assert(0, `Поле только для чтения`); }
		void isNullable(bool nullable) @property //Установка возможности быть пустым
		{	assert(0, `Поле только для чтения`); }

		void opIndexAssign(int value, size_t key)
		{	assert(0, `Поле только для чтения`); }
		void opIndexAssign(string value, size_t key)
		{	assert(0, `Поле только для чтения`); }
		void opIndexAssign(bool value, size_t key)
		{	assert(0, `Поле только для чтения`); }
		
		size_t _frontKey() @property
		{	if( _iter < _keys.length )
				return _keys[_iter];
			assert(0, "Выход за границы дипазона") ;
		}
	} //override
	
	void add(size_t key) //Добавление ключа к концу списка
	{	size_t count = _indexes.length;
		_indexes[key] = count;
		_keys ~= key;
	}
	
	//Добавление массивов с данными к полю данных
	void addData( const ref size_t[] keys )
	{	foreach(key; keys)
		{	size_t count = _indexes.length;
			_indexes[key] = count;
		}
		_keys ~= keys;
	}
	
	bool keyExists(size_t key)
	{	if( key in _indexes ) return true;
		return false;
	}
	
	size_t _getIndex(size_t key)
	{	if( key in _indexes )
			return _indexes[key];
		assert(0);
		//else
			//TODO: Выдавать ошибку
	}

	/*void _printData()
	{	foreach( key, value; _indexes )
		{	writeln(key.to!string ~ `  =  ` ~ value.to!string);
			
		}
		
	}*/
}


class Field(FieldType FieldT): IField
{
	//Определяем настоящий тип значения по семантическому типу поля
	alias GetFieldValueType!(FieldT) T;
		
	alias string[int] EnumValuesType;
	
protected: ///ВНУТРЕННИЕ ПОЛЯ КЛАССА
	T[] _values;
	bool[] _nullFlags;
	KeyField _keyField;

	//Поля от формата поля
	bool _isNullable = true;
	immutable FieldType _type = FieldT;
	immutable string _name;
	
	//static if( FieldT == FieldType.Enum )
	//	immutable(EnumValuesType) _enumValues;

public:
	this( string name )
	{	_name = name; }
	
	this( string name, KeyField keyField )
	{	_name = name; _keyField = keyField; }
	
	this( IFieldFormat format )
	{	_name = format.name;
		_isNullable = format.isNullable;
		if( format.linkField.type == FieldType.IntKey )
			_keyField = cast(KeyField) format.linkField;
		//else
			//TODO: Подумать, что делать если не ключевое поле
	}
	
	this( string name, KeyField keyField, bool isNullable )
	{	_name = name;
		_keyField = keyField;
		_isNullable = isNullable;
	}
	
	//static if( FieldT == FieldType.Enum )
	/*this( string name, EnumValuesType enumValues, bool nullEnabled )
	{	_name = format.name;
		_nullEnabled = nullEnabled;
	}*/
	
	///РЕАЛИЗАЦИИ ИНТЕРФЕЙСНЫХ МЕТОДОВ КЛАССА
	override {
		FieldType type() @property //Возвращает тип поля данных
		{	return _type; }
		size_t length() @property //
		{	return _values.length; }
		string name() @property
		{	return _name; }
		bool isNull(size_t key)
		{	if( _isNullable )
				return ( keyExists(key) ) ? _nullFlags[ _getIndex(key) ] : true;
			else return false;
		}
		void setNull(size_t key)
		{	if( keyExists(key) )
				_nullFlags[ _getIndex(key) ] = true;
			//else //TODO: Добавить исключение
		}
		bool isNullable()
		{	return _isNullable; }
		void isNullable(bool nullable)
		{	_isNullable = nullable; }
		bool isWriteable() @property
		{	return true; }
		
		ICell front() @property
		{	return new Cell( this, _keyField._frontKey() ); }
		void popFront()
		{	_keyField.popFront(); }
		bool empty() @property
		{	return _keyField.empty; }
		
		ICell opIndex(size_t key)  
		{	if( keyExists(key) )
				return new Cell( this, key );
			else
				assert( _getErrorMsgIndexOutOfBounds( _getIndex(key), _values.length) );
			assert(0); //Сюда не должно попасть
		}
		
		void opIndexAssign( int value, size_t key)
		{	set( fldConv!( _type )( value ), key ); }
		void opIndexAssign( string value, size_t key )
		{	set( fldConv!( _type )( value ), key ); }
		void opIndexAssign( bool value, size_t key )
		{	set( fldConv!( _type )( value ), key ); }

		
		int getInt(size_t key)
		{	if( isNull(key) ) assert(0);
			return fldConv!( FieldType.Int )( _values[ _getIndex(key) ] ); 
		}
		string getStr(size_t key)
		{	if( isNull(key) ) assert(0);
			return fldConv!( FieldType.Str )( _values[ _getIndex(key) ] ); 
		}
		bool getBool(size_t key)
		{	if( isNull(key) ) assert(0);
			return fldConv!( FieldType.Bool )( _values[ _getIndex(key) ] ); 
		}
		
		size_t _frontKey()
		{	return _keyField._frontKey(); }
	}
	
	///СОБСТВЕННЫЕ НЕИНТЕРФЕЙСНЫЕ МЕТОДЫ КЛАССА ПОЛЯ
	void set( size_t key, T value )
	{	if( !keyExists(key) ) assert(0);
		_nullFlags[ _getIndex(key) ] = false;
		//Значение должно копироваться (для текста)
		_values[ _getIndex(key) ] = value;
	}
	
	//Добавление массивов с данными к полю данных
	void addData( const ref T[] newValues, const ref bool[] newNullFlags)
	{	//if( newValues.length == newNullFlags.length )
		//{	
		_values ~= newValues;
		_nullFlags ~= newNullFlags;
		//}
		//else
			//assert(0, `Входные данные не совпадают по размеру`);
	}
	
	///Получает значение ячейки поля
	T get(size_t key)  
	{	if( isNull(key) ) assert(0);
		else return _values[ _getIndex(key) ];
	}

	void add(T value) //Добавление значения к концу списка
	{	_values ~= value;
		_nullFlags ~= false; //Не нулевое значение
	}
	
	bool keyExists(size_t key)
	{	return _keyField.keyExists(key);
	}
	
	
	///СЛУЖЕБНЫЕ И ВНУТРЕННИЕ ИНТЕРФЕЙСНЫЕ МЕТОДЫ
	/*override void _setLength(size_t fldLength)
	{	_values.length = fldLength;
		_nullFlags.length = fldLength;
	}*/
	
	size_t _getIndex(size_t key)
	{	return _keyField._getIndex(key);
	}
	
	void _setKeyField(KeyField keyField)
	{	_keyField = keyField;
	}
	
protected:  ///ЗАКРЫТЫЕ МЕТОДЫ
	string _getErrorMsgIndexOutOfBounds(size_t index, size_t length)
	{	return `Индекс "` ~ index.to!string 
		~ `" выходит за границы отведённого диапазона: [0; ` 
		~ length.to!string ~ `)`;
	}
	
}