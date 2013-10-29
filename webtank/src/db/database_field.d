module webtank.db.database_field;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database;



///Класс ключевого поля
class DatabaseField(FieldType FieldT) : IField!( FieldT )
{
protected: ///ВНУТРЕННИЕ ПОЛЯ КЛАССА
	alias GetFieldValueType!(FieldT) T;

	IDBQueryResult _queryResult;
	immutable(size_t) _fieldIndex;
	immutable string _name = "";
	
	

	//Поля от формата поля
	static if( isKeyFieldType!(FieldT))
	{	size_t[size_t] _indexes;
	// 	size_t _iter = 0; //Итератор, который проходит по всем ключам массива индексов
		size_t[] _keys;   //Массив ключей

	}
	else
	{	bool _isNullable = true;
// 		bool[] _nullFlags;
// 		T[] _values;
		bool _isWriteable = false;
	}
	
	static if( FieldT == FieldType.Enum )
	{	EnumFormat _enumFormat;
	}

public:
	this( IDBQueryResult queryResult, size_t fieldIndex = 0 )
	{	_queryResult = queryResult;
		_fieldIndex = fieldIndex;
		static if( isKeyFieldType!(FieldT) )
			_readKeys();
	}

	
	override { //Переопределяем интерфейсные методы
		FieldType type()
		{	return FieldT; }
		size_t length()
		{	static if( isKeyFieldType!(FieldT) )
				return _indexes.length;
			else
				return _queryResult.recordCount;
		}
		string name() @property
		{	return _name; }
		
		bool isNullable() @property
		{	static if( isKeyFieldType!(FieldT) )
				return false;
			else
				return _isNullable;
		
		}
		bool isWriteable() @property
		{	static if( isKeyFieldType!(FieldT) )
				return false;
			else
				return _isWriteable;
		}
		
		//Ключевое поле всегда не пустое
		bool isNull(size_t index)
		{	static if( isKeyFieldType!(FieldT) )
				return false;
			else
			{	import std.conv;
				assert( index <= _queryResult.recordCount, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because record count is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
				return ( _isNullable ? _queryResult.isNull( _fieldIndex, index ) : false );
			}
		}
		
		T get(size_t index)
		{	static if( isKeyFieldType!(FieldT) )
			{	assert( index <= _indexes.length, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because _indexes.length is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
				assert( !isNull(index), "Key field value must not be null!!!" );
			}
			else
				assert( index <=  _queryResult.recordCount, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because record count is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
			return fldConv!( FieldT )( _queryResult.get(_fieldIndex, index) );
		}
		T get(size_t index, T defaultValue)
		{	static if( isKeyFieldType!(FieldT) )
				assert( index <= _indexes.length, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because _indexes.length is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
			else
				assert( index <= _queryResult.recordCount, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because record count is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
			return ( isNull(index) ? defaultValue : fldConv!( FieldT )( _queryResult.get(_fieldIndex, index) ) );
		}
		
		string getStr(size_t index, string defaultValue = null)
		{	static if( isKeyFieldType!(FieldT) )
			{	assert( index <= _indexes.length, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because _indexes.length is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
				assert( isNull(index), "Key field value must not be null!!!" );
			}
			else
				assert( index <= _queryResult.recordCount, "Field index '" ~ std.conv.to!string(index) ~ "' is out of bounds, because record count is '" ~ std.conv.to!string(_queryResult.recordCount) ~ "'!!!" );
			
			
			return ( isNull(index) ? defaultValue : _queryResult.get(_fieldIndex, index) );
		}
		
		static if( FieldT == FieldType.Enum )
		{	EnumFormat getEnum()
			{	return _enumFormat;
			}
			
			void _initEnum( const string[int] enumMap )
			{	_enumFormat = new EnumFormat(enumMap);
			}
		}

// 		//Методы и свойства по работе с диапазоном
// 		ICell front() @property
// 		{	if( _iter < _keys.length )
// 				return new Cell( this, _keys[_iter]  );
// 			assert(0, "Выход за границы дипазона") ;
// 		}
// 		bool empty() @property
// 		{	if ( _iter >= _indexes.length )
// 			{	_iter = 0;
// 				return true; 
// 			}
// 			else return false;
// 		}
// 		void popFront()
// 		{	_iter++; 
// 		}
		
// 		void setNull(size_t index) //Установить значение ячейки в null
// 		{	assert(0, _readOnyMessage); }
// 		void isNullable(bool nullable) @property //Установка возможности быть пустым
// 		{	assert(0, _readOnyMessage); }


// 				size_t _frontKey() @property
// 				{	if( _iter < _keys.length )
// 						return _keys[_iter];
// 					assert(0, "Выход за границы дипазона") ;
// 				}

		static if( isKeyFieldType!(FieldT) )
		{	size_t getIndex(size_t key)
			{	if( key in _indexes )
					return _indexes[key];
				assert(0, "Ключ не найден!!!");
				//else
					//TODO: Выдавать ошибку
			}
			
			size_t getKey(size_t index)
			{	if( index < _keys.length )
					return _keys[index];
				assert(0, "Ключ не найден!!!");
				//else
					//TODO: Выдавать ошибку
			}
		}
		
			
	} //override
	
	
	static if( ! isKeyFieldType!(FieldT) )
	{
			
		void _setNullable(bool nullable)
		{	_isNullable = nullable;
		}
	}
	
// 	bool keyExists(size_t key)
// 	{	if( key in _indexes ) return true;
// 		return false;
// 	}
	
	
	
protected:

	static if( isKeyFieldType!(FieldT) )
	{
		void _readKeys()
		{	auto recordCount = _queryResult.recordCount;
			for( size_t i = 0; i < recordCount; i++ )
			{	auto key = std.conv.to!(size_t)( _queryResult.get(_fieldIndex, i) );
				_keys ~= key;
				_indexes[key] = i;
			}
		}
	}
	
	// 	void set( T value, size_t key )
	// 	{	if( !keyExists(key) ) assert(0);
	// 		_nullFlags[ _getIndex(key) ] = false;
	// 		//Значение должно копироваться (для текста)
	// 		_values[ _getIndex(key) ] = value;
	// 	}

}

