module webtank.datctrl.record_set;

import std.typetuple, std.typecons, std.stdio, std.conv;

//import std.stdio;

import webtank.datctrl.data_field, webtank.datctrl.record, webtank.datctrl.record_format;


template RecordSet(alias RecFormat)
{
	alias Tuple!( getTupleOfByFieldSpec!(IField, RecFormat.fieldSpecs) ) IFieldTupleType;
	alias Record!RecFormat Rec;
	
	class RecordSet
	{	
	protected:
		IFieldTupleType _fields;
		size_t _keyFieldIndex;
		
		size_t _currRecIndex;
	public:
		Rec opIndex(size_t key) 
		{	return new Rec(this, key);
		}
	
		template get(string fieldName)
		{	alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
			alias getFieldSpecIndex!(fieldName, RecFormat.fieldSpecs) fieldIndex;
			
			ValueType get(size_t recordKey)
			{	return _fields[fieldIndex].get( _getRecordIndex(recordKey) );
			}

			ValueType get(size_t recordKey, ValueType defaultValue)
			{	return _fields[fieldIndex].get( _getRecordIndex(recordKey), defaultValue );
			}
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
		
		
// 		string getStr(string fieldName, size_t recordKey)
// 		{	
// 			
// 		}
		
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
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).name currFieldName;
				if( currFieldName == fieldName )
				{	return field.isNull( _getRecordIndex(recordKey) );
				}
			}
			assert(0);
		}
		
		bool isNullable(string fieldName)
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).name currFieldName;
				if( currFieldName == fieldName )
				{	return field.isNullable();
				}
			}
			assert(0);
		}
		
		size_t length() @property
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).fieldType currFieldType;
				static if( currFieldType == FieldType.IntKey )
				{	if( i == _keyFieldIndex )
						return field.length;
				}
			}
			assert(0);
		}
		
		template _setField(string fieldName)
		{	
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias getFieldSpecIndex!(fieldName, RecFormat.fieldSpecs) fieldIndex;
			alias IField!(fieldType) FieldIface;
			
			void _setField( FieldIface field )
			{	_fields[fieldIndex] = field;
			}
		}
		
	protected:
		size_t _getRecordIndex(size_t key)
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).fieldType currFieldType;
				static if( currFieldType == FieldType.IntKey )
				{	if( i == _keyFieldIndex )
						return field.getIndex(key);
				}
			}
			assert(0);
		}
		
		size_t _getRecordKey(size_t index)
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).fieldType currFieldType;
				static if( currFieldType == FieldType.IntKey )
				{	if( i == _keyFieldIndex )
						return field.getKey(index);
				}
			}
			assert(0);
		}
		
	}
}


