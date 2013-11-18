module webtank.datctrl.record_set;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv, std.json;

//import std.stdio;

import webtank.datctrl.data_field, webtank.datctrl.record, webtank.datctrl.record_format, webtank.common.serialization;

// interface IBaseRecordSet
// {	
// 	
// }

template RecordSet(alias RecFormat)
{
	class RecordSet: /+IBaseRecordSet,+/ IStdJSONSerializeable
	{	
	public:
		alias Record!RecFormat Rec;
		alias RecFormat RecordFormatType;
		
	protected:
		IBaseField[] _fields;
		RecFormat _format;
		
		
		size_t _currRecIndex;
	public:

		//Сериализация данных записи с индексом index в std.json
		JSONValue serializeDataAt(size_t index)
		{	JSONValue recJSON;
			recJSON.type = JSON_TYPE.ARRAY;
			recJSON.array.length = RecFormat.fieldSpecs.length; 
			foreach( j, spec; RecFormat.fieldSpecs )
			{	if( this.isNull(spec.name, _getRecordKey(index) ) )
					recJSON[j].type = JSON_TYPE.NULL;
				else
					recJSON[j] = 
						webtank.common.serialization.getStdJSON( this.get!(spec.name)( _getRecordKey(index) ) );
			}
			return recJSON;
		}
		
		//Сериализация объекта в std.json
		JSONValue getStdJSON()
		{	
			auto jValue = _format.getStdJSON();
			JSONValue recordsJSON;
				recordsJSON.type = JSON_TYPE.ARRAY;
			foreach( i; 0..this.length )
				recordsJSON.array ~= this.serializeDataAt(i);
			
			jValue.object["d"] = recordsJSON;
			jValue.object["t"] = JSONValue();
			jValue.object["t"].type = JSON_TYPE.STRING;
			jValue.object["t"].str = "recordset";

			return jValue;
		}
		
		this(RecFormat fieldFormat)
		{	_format = fieldFormat;
			//Устанавливаем размер массива полей
			_fields.length = RecFormat.fieldSpecs.length; 
		}
	
		//Оператор получения записи по индексу
		Rec opIndex(size_t index) 
		{	return new Rec(this, _getRecordKey(index));
		}
		
		//Получить запись на позиции с номером index
		Rec getRecordAt(size_t index)
		{	return new Rec(this, _getRecordKey(index));
		}
		
		//Получить запись с заданным ключом key
		Rec getRecord(size_t key)
		{	return new Rec(this, key);
		}
	
		template get(string fieldName)
		{	alias getFieldSpec!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
			alias getFieldSpec!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias getFieldIndex!(fieldName, RecFormat.fieldSpecs) fieldIndex;
			
			ValueType get(size_t recordKey)
			{	auto currField = cast(IField!(fieldType)) _fields[fieldIndex];
				return currField.get( _getRecordIndex(recordKey) );
			}

			ValueType get(size_t recordKey, ValueType defaultValue)
			{	auto currField = cast(IField!(fieldType)) _fields[fieldIndex];
				return currField.get( _getRecordIndex(recordKey), defaultValue );
			}
		}
		
		//Функция получения формата для перечислимого типа
		//Определена только для полей, имеющих перечислимый тип, что логично
		template getEnum(string fieldName)
		{	alias getFieldSpec!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias getFieldIndex!(fieldName, RecFormat.fieldSpecs) fieldIndex;
			
			static if( fieldType == FieldType.Enum )
			{	auto getEnum()
				{	auto currField = cast(IField!(fieldType)) _fields[fieldIndex];
					return currField.getEnum(fieldIndex);
				}
			}
			else
				static assert( 0, "Getting enum data is only available for enum field types!!!" );
		}

		string getStr(string fieldName, size_t recordKey, string defaultValue = null)
		{	auto currField = _fields[ RecFormat.indexes[fieldName] ];
			return currField.getStr( _getRecordIndex(recordKey), defaultValue );
		}
		
		Rec front() @property
		{	return new Rec( this, _getRecordKey(_currRecIndex) );
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
		
		size_t keyFieldIndex() @property
		{	return _format.keyFieldIndex;
		}
		
		void setKeyField(size_t index)
		{	auto keyFieldIndexes = getKeyFieldIndexes!(RecFormat.fieldSpecs)();
			foreach( i; keyFieldIndexes )
			{	if( i == index )
				{	_format.keyFieldIndex = index;
					return;
				}
			}
			assert( 0, "Field with index \"" ~ index.to!string ~ "\" isn't found or can't be used as primary key!" );
		}
		
		bool isNull(string fieldName, size_t recordKey)
		{	auto currField = _fields[ RecFormat.indexes[fieldName] ];
			return currField.isNull( _getRecordIndex(recordKey) );
		}
		
		bool isNullable(string fieldName)
		{	auto currField = _fields[ RecFormat.indexes[fieldName] ];
			return currField.isNullable();
		}
		
		size_t length() @property
		{	assert( _fields[_format.keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _format.keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IField!(FieldType.IntKey) ) _fields[_format.keyFieldIndex];
			return keyField.length;
		}
		
		template _setField(string fieldName)
		{	alias getFieldSpec!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias getFieldIndex!(fieldName, RecFormat.fieldSpecs) fieldIndex;
			
			void _setField( IField!(fieldType) field )
			{	_fields[fieldIndex] = field;
			}
		}
		
		auto format() @property
		{	return _format; }
		
	protected:
		size_t _getRecordIndex(size_t key)
		{	assert( _fields[_format.keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _format.keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IField!(FieldType.IntKey) ) _fields[_format.keyFieldIndex];
			return keyField.getIndex(key);
		}
		
		size_t _getRecordKey(size_t index)
		{	assert( _fields[_format.keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _format.keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IField!(FieldType.IntKey) ) _fields[_format.keyFieldIndex];
			return keyField.getKey(index);
		}
		
	}
}


} //static if( isDatCtrlEnabled )
