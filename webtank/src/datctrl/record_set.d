module webtank.datctrl.record_set;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.stdio, std.conv;

//import std.stdio;

import webtank.datctrl.data_field, webtank.datctrl.record, webtank.datctrl.record_format;

interface IBaseRecordSet
{	
	
}

template RecordSet(alias RecFormat)
{
// 	alias Tuple!( getTupleTypeOf!(IField, RecFormat.fieldSpecs) ) IFieldTupleType;
	
	
	class RecordSet: IBaseRecordSet
	{	
	public:
		alias Record!RecFormat Rec;
		alias RecFormat RecordFormatType;
		
	protected:
		IBaseField[] _fields;
		size_t _keyFieldIndex;
		RecFormat _format;
		
		
		size_t _currRecIndex;
	public:

		this(RecFormat fieldFormat)
		{	_format = fieldFormat;
			//Устанавливаем размер массива полей
			_fields.length = RecFormat.fieldSpecs.length; 
		}
	
		Rec opIndex(size_t key) 
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
		{	return _keyFieldIndex;
		}
		
		void setKeyField(size_t index)
		{	auto keyFieldIndexes = getKeyFieldIndexes!(RecFormat.fieldSpecs)();
			foreach( i; keyFieldIndexes )
			{	if( i == index )
				{	_keyFieldIndex = index;
					return;
				}
			}
			assert( 0, "Поле с индексом \"" ~ index.to!string ~ "\" не найдено или не может быть выбрано в качестве первичного ключа!" );
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
		{	assert( _fields[_keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IField!(FieldType.IntKey) ) _fields[_keyFieldIndex];
			return keyField.length;
		}
		
		template _setField(string fieldName)
		{	alias getFieldSpec!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias getFieldIndex!(fieldName, RecFormat.fieldSpecs) fieldIndex;
			
			void _setField( IField!(fieldType) field )
			{	_fields[fieldIndex] = field;
			}
		}
		
	protected:
		size_t _getRecordIndex(size_t key)
		{	assert( _fields[_keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IField!(FieldType.IntKey) ) _fields[_keyFieldIndex];
			return keyField.getIndex(key);
		}
		
		size_t _getRecordKey(size_t index)
		{	assert( _fields[_keyFieldIndex].type == FieldType.IntKey, "Field with index " 
				~ _keyFieldIndex.to!string ~ " is not a key field!!!" ); 
			auto keyField = cast( IField!(FieldType.IntKey) ) _fields[_keyFieldIndex];
			return keyField.getKey(index);
		}
		
	}
}


} //static if( isDatCtrlEnabled )