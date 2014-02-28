module webtank.datctrl.record_set;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv, std.json;

import webtank.datctrl.data_field, webtank.datctrl.record, webtank.datctrl.record_format, webtank.common.serialization;

// interface IBaseRecordSet
// {	
// 	
// }

///Класс реализует работу с набором записей
template RecordSet(alias RecordFormatT)
{
	class RecordSet: /+IBaseRecordSet,+/ IStdJSONSerializeable
	{	
		///Тип формата для набора записей
		alias RecordFormatT FormatType; 
		
		///Тип записи, возвращаемый из набора записей
		alias Record!FormatType RecordType;  
		
	protected:
		IBaseDataField[] _dataFields;
		size_t _keyFieldIndex;
		
		size_t _currRecIndex;
	public:

		///Сериализация данных записи с индексом index в std.json
		JSONValue getStdJSONDataAt(size_t index)
		{	JSONValue recJSON;
			recJSON.type = JSON_TYPE.ARRAY;
			recJSON.array.length = FormatType.tupleOfNames!().length;
			
			foreach( j, name; FormatType.tupleOfNames!() )
			{	if( this.isNull(name, getRecordKey(index) ) )
					recJSON[j].type = JSON_TYPE.NULL;
				else
					recJSON[j] = 
						webtank.common.serialization.getStdJSON( this.get!(name)( getRecordKey(index) ) );
			}
			return recJSON;
		}
		
		
		///Сериализует формат набора записей в std.json
		JSONValue getStdJSONFormat()
		{	JSONValue jValue = JSONValue();
			jValue.type = JSON_TYPE.OBJECT;
			
			//Выводим номер ключевого поля
			jValue.object["kfi"] = JSONValue();
			jValue.object["kfi"].type = JSON_TYPE.UINTEGER;
			jValue.object["kfi"].uinteger = _keyFieldIndex;
			
			//Выводим тип данных
			jValue.object["t"] = JSONValue();
			jValue.object["t"].type = JSON_TYPE.STRING;
			jValue.object["t"].str = "recordset";
			
			//Образуем JSON-массив форматов полей
			jValue.object["f"] = JSONValue();
			jValue.object["f"].type = JSON_TYPE.ARRAY;
			
			foreach( field; _dataFields )
				jValue["f"].array ~= field.getStdJSONFormat();

			return jValue;
		}
		
		///Сериализация объекта в std.json
		JSONValue getStdJSON()
		{	auto jValue = this.getStdJSONFormat();
			
			jValue.object["d"] = JSONValue();
			jValue.object["d"].type = JSON_TYPE.ARRAY;
			jValue.object["d"].array.length = this.length;
			
			foreach( i; 0..this.length )
				jValue["d"].array[i] = this.getStdJSONDataAt(i);

			return jValue;
		}
		
		this(IBaseDataField[] dataFields)
		{	//Устанавливаем размер массива полей
			_dataFields = dataFields; 
		}
	
		///Оператор получения записи по индексу
		RecordType opIndex(size_t recordIndex) 
		{	return getRecordAt(recordIndex); }
		
		///Метод получения записи по её индексу в наборе
		RecordType getRecordAt(size_t recordIndex)
		{	return getRecord( getRecordKey(recordIndex) ); }
		
		///Метод получения записи по её значению первичного ключа
		RecordType getRecord(size_t recordKey)
		{	return new RecordType(this, recordKey); }
		
		///Методы получения значения ячейки данных по имени поля и значению первичного ключа записи
		template get(string fieldName)
		{	alias FormatType.getValueType!(fieldName) ValueType;
			
			ValueType get(size_t recordKey)
			{	return getAt!(fieldName)( getRecordIndex(recordKey) ); }

			ValueType get(size_t recordKey, ValueType defaultValue)
			{	return getAt!(fieldName)( getRecordIndex(recordKey), defaultValue ); }
		}
		
		///Методы получения значения ячейки данных по имени поля и индексу записи в наборе
		template getAt(string fieldName)
		{	alias FormatType.getValueType!(fieldName) ValueType;
			alias FormatType.getFieldType!(fieldName) fieldType;
			alias FormatType.getFieldIndex!(fieldName) fieldIndex;
			
			ValueType getAt(size_t recordIndex)
			{	auto currField = cast(IDataField!(fieldType)) _dataFields[fieldIndex];
				return currField.get( recordIndex );
			}

			ValueType getAt(size_t recordIndex, ValueType defaultValue)
			{	auto currField = cast(IDataField!(fieldType)) _dataFields[fieldIndex];
				return currField.get( recordIndex, defaultValue );
			}
		}
		
		///Функция получения формата для перечислимого типа
		///Определена только для полей, имеющих перечислимый тип, что логично
		template getEnumFormat(string fieldName)
		{	alias FormatType.getValueType!(fieldName) ValueType;
			alias FormatType.getFieldType!(fieldName) fieldType;
			alias FormatType.getFieldIndex!(fieldName) fieldIndex;
			
			static if( fieldType == FieldType.Enum )
			{	auto getEnumFormat()
				{	auto currField = cast(IDataField!(fieldType)) _dataFields[fieldIndex];
					return currField.enumFormat();
				}
			}
			else
				static assert( 0, "Getting enum data is only available for enum field types!!!" );
		}

		///Метод получения "сырого" строкового представления значения ячейки данных
		///по имени поля и значению первичного ключа записи
		string getStr(string fieldName, size_t recordKey, string defaultValue = null)
		{	return this.getStrAt( fieldName, getRecordIndex(recordKey), defaultValue ); }
		
		///Метод получения "сырого" строкового представления значения ячейки данных
		///по имени поля и индексу записи в наборе
		string getStrAt(string fieldName, size_t recordIndex, string defaultValue = null)
		{	auto currField = _dataFields[ FormatType.indexes[fieldName] ];
			return currField.getStr( recordIndex, defaultValue );
		}
		
		RecordType front() @property
		{	return new RecordType( this, getRecordKey(_currRecIndex) );
		}
		
		void popFront()
		{	_currRecIndex++; }
		
		bool empty() @property
		{	if( _currRecIndex < this.length  )
				return false;
			else
			{	_currRecIndex = 0;
				return true;
			}
		}
		
		///Метод возвращает порядковый номер первичного ключа в наборе записей
		size_t keyFieldIndex() @property
		{	return _keyFieldIndex;
		}
		
		///Метод задаёт какое поле является первичным ключом набора записей
		///через задание порядкового номера поля
		void setKeyField(size_t index)
		{	auto keyFieldIndexes = getKeyFieldIndexes!(FormatType._fieldSpecs)();
			foreach( i; keyFieldIndexes )
			{	if( i == index )
				{	_keyFieldIndex = index;
					return;
				}
			}
			assert( 0, "Field with index \"" ~ index.to!string ~ "\" isn't found or can't be used as primary key!" );
		}
		
		///Метод возвращает true, если значение ячейки поля с именем fieldName
		///и значением первичного ключа recordKey записи является пустым (null). Иначе false.
		bool isNull(string fieldName, size_t recordKey)
		{	return this.isNullAt( fieldName, getRecordIndex(recordKey) ); }
		
		///Метод возвращает true, если значение ячейки поля с именем fieldName
		///и индексом записи в наборе recordIndex является пустым (null). Иначе false.
		bool isNullAt(string fieldName, size_t recordIndex)
		{	auto currField = _dataFields[ FormatType.indexes[fieldName] ];
			return currField.isNull( recordIndex );
		}
		
		///Возвращает true, если поле с именем fieldName может иметь пустое значение (null)
		///В противном случае возвращается false
		bool isNullable(string fieldName)
		{	auto currField = _dataFields[ FormatType.indexes[fieldName] ];
			return currField.isNullable();
		}
		
		///Возвращает количество записей в наборе
		size_t length() @property
		{	assert( _dataFields[_keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IDataField!(FieldType.IntKey) ) _dataFields[_keyFieldIndex];
			return keyField.length;
		}
		
		///Метод возвращает порядковый номер записи по первичному ключу
		size_t getRecordIndex(size_t key)
		{	assert( _dataFields[_keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IDataField!(FieldType.IntKey) ) _dataFields[_keyFieldIndex];
			return keyField.getIndex(key);
		}
		
		///Метод возвращает первичный ключ записи по её порядковому номеру в наборе записей
		size_t getRecordKey(size_t index)
		{	assert( _dataFields[_keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IDataField!(FieldType.IntKey) ) _dataFields[_keyFieldIndex];
			return keyField.getKey(index);
		}
		
	}
}


} //static if( isDatCtrlEnabled )
