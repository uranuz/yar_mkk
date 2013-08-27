module webtank.db.database_field;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database;


template DatabaseField(FieldType FieldT)
{	static if( FieldT == FieldType.IntKey )
	{
		///Класс ключевого поля
		class DatabaseField : IField!( FieldT )
		{
		protected:
			alias GetFieldValueType!(FieldT) T;

			size_t[size_t] _indexes;
			immutable(string) _name = "";
		// 	size_t _iter = 0; //Итератор, который проходит по всем ключам массива индексов
			size_t[] _keys;   //Массив ключей
			
		// 	immutable(string) _readOnyMessage = `Поле только для чтения`;
			
			IDBQueryResult _queryResult;
			immutable(size_t) _fieldIndex;
			
		public:
			this( IDBQueryResult queryResult, size_t fieldIndex = 0 )
			{	_queryResult = queryResult;
		// 		_name = fieldName;
				_fieldIndex = fieldIndex;
				_readKeys();
			}
			
			this() { _fieldIndex = 0; }
			
			override { //Переопределяем интерфейсные методы
				FieldType type()
				{	return FieldT; }
				size_t length()
				{	return _indexes.length; }
				string name() @property
				{	return _name; }
				
				bool isNullable() @property
				{	return false; }
				bool isWriteable() @property
				{	return false; }
				
				bool isNull(size_t index)
				{	if( index in _indexes ) return false; 
					return true;
				}
				
				T getValue(size_t index)
				{	return fldConv!( FieldT )( _queryResult.getValue(index, _fieldIndex) );
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
			} //override
			
			bool keyExists(size_t key)
			{	if( key in _indexes ) return true;
				return false;
			}
			
			size_t getIndex(size_t key)
			{	if( key in _indexes )
					return _indexes[key];
				assert(0);
				//else
					//TODO: Выдавать ошибку
			}
			
		protected:

			void _readKeys()
			{	auto recordCount = _queryResult.recordCount;
				for( size_t i = 0; i < recordCount; i++ )
				{	auto key = std.conv.to!(size_t)( _queryResult.getValue(i, _fieldIndex) );
					_keys ~= key;
					_indexes[key] = i;
				}
			}

		}
	}
	else
	{

		class DatabaseField: IField!( FieldT )
		{
			//Определяем настоящий тип значения по семантическому типу поля
			alias GetFieldValueType!(FieldT) T;
				
			alias string[int] EnumValuesType;
			
		protected: ///ВНУТРЕННИЕ ПОЛЯ КЛАССА
		// 	T[] _values;
// 			bool[] _nullFlags;


			//Поля от формата поля
			bool _isNullable = true;
			immutable FieldType _type = FieldT;
			immutable string _name = "";
			
			//static if( FieldT == FieldType.Enum )
			//	immutable(EnumValuesType) _enumValues;
			
			IDBQueryResult _queryResult;
			immutable(size_t) _fieldIndex;

		public:
			this( IDBQueryResult queryResult, size_t fieldIndex = 0 )
			{	_queryResult = queryResult;
		// 		_name = fieldName;
				_fieldIndex = fieldIndex;
			}
			
			this() { _fieldIndex = 0; }
			
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
				{	return _queryResult.recordCount; }
				string name() @property
				{	return _name; }
				bool isNull(size_t index)
				{	if( _isNullable )
						return ( index < _queryResult.recordCount ) ? _queryResult.getIsNull( index, _fieldIndex ) : true;
					else return false;
				}
				
				T getValue(size_t index)  
				{	if( isNull(index) ) assert(0);
					else return fldConv!( FieldT )( _queryResult.getValue(index, _fieldIndex) );
				}
				
		// 		void setNull(size_t key)
		// 		{	if( keyExists(key) )
		// 				_nullFlags[ _getIndex(key) ] = true;
		// 			//else //TODO: Добавить исключение
		// 		}
				bool isNullable()
				{	return _isNullable; }
// 				void isNullable(bool nullable)
// 				{	_isNullable = nullable; }
				bool isWriteable() @property
				{	return true; }
			
		// 		ICell front() @property
		// 		{	return new Cell( this, _keyField._frontKey() ); }
		// 		void popFront()
		// 		{	_keyField.popFront(); }
		// 		bool empty() @property
		// 		{	return _keyField.empty; }
			}
			
			///СОБСТВЕННЫЕ НЕИНТЕРФЕЙСНЫЕ МЕТОДЫ КЛАССА ПОЛЯ
		// 	void set( T value, size_t key )
		// 	{	if( !keyExists(key) ) assert(0);
		// 		_nullFlags[ _getIndex(key) ] = false;
		// 		//Значение должно копироваться (для текста)
		// 		_values[ _getIndex(key) ] = value;
		// 	}
		// 	


		}
	
	
	}
}