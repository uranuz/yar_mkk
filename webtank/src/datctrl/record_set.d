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
		
		
	public:
		Rec opIndex(size_t index) 
		{	return new Rec(this, index);
		}
	
		template getValue(string fieldName)
		{
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			
			ValueType getValue(size_t recordKey)
			{	auto fieldIndex = getFieldSpecIndex!(fieldName, RecFormat.fieldSpecs);
				foreach( i, field; _fields )
				{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).fieldType currFieldType;
					static if( currFieldType == fieldType )
					{	if( i == fieldIndex )
						{	return field.getValue( getRecordIndex(recordKey) );
						}
					}
				}
				assert(0);
			}
			
			
		}
		
		size_t getRecordIndex(size_t key)
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).fieldType currFieldType;
				static if( currFieldType == FieldType.IntKey )
				{	if( i == _keyFieldIndex )
						return field.getIndex(key);
				}
			}
			assert(0);
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
		
		template _setField(string fieldName)
		{	
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias IField!(fieldType) FieldIface;
			void _setField( FieldIface field )
			{	immutable fieldIndex = getFieldSpecIndex!(fieldName, RecFormat.fieldSpecs);
				_fields[fieldIndex] = field;
			}
		}
		
		bool isNull(string fieldName, size_t recordKey)
		{	foreach( i, field; _fields )
			{	alias getFieldSpecByIndex!(i, RecFormat.fieldSpecs).name currFieldName;
				if( currFieldName == fieldName )
				{	return field.isNull( getRecordIndex(recordKey) );
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
		
	}
}

// class RecordSet   //: IRecordSet
// {	
// protected:
// 	IField[] _fields;
// 	size_t[string] _indexes;
// 	//string[] _names;
// 
// public:
// 	Record opIndex(size_t key)  //Оператор получения записи по индексу
// 	{	//if( index < _fields[0].length )
// 			return new Record(this, key);
// 		//else return null;
// 	}
// 	
// 	Record front() @property
// 	{	return new Record( this, _fields[0]._frontKey );
// 	}
// 	
// 	void popFront()
// 	{	_fields[0].popFront(); }
// 	
// 	bool empty() @property
// 	{	return _fields[0].empty;
// 	}
// 	
// 	size_t _frontKey() @property
// 	{	return _fields[0]._frontKey; }
// 	
// 	//this(IRecordFormat format)
// 	
// 	IField getField(string name)
// 	{	if( (_indexes !is null) && (name in _indexes) )
// 			return _fields[ _indexes[name] ];
// 		else return null;
// 	}
// 	
// 	IField getField(size_t index)
// 	{	if( index < _fields.length )
// 			return _fields[index];
// 		else return null;
// 	}
// 
// 	size_t recordCount() @property
// 	{	if( _fields.length > 0 ) 
// 			return _fields[0].length;
// 		else  return 0;
// 	}
// 	
// 	size_t fieldCount() @property
// 	{	return _fields.length; }
// 	
// 	bool hasField(string name)
// 	{	return (name in _indexes) ? true : false;
// 	}new_
// 	
// 	void addField(IField field)
// 	{	size_t count = _fields.length;
// 		_indexes[field.name] = count;
// 		_fields ~= field;
// 	}
// 	
// 	/*void _insertField(IField field, size_t pos)
// 	{	if( pos < _fields.length )
// 			_fields.insertInPlace(pos, field);
// 		//else
// 		//	assert( _getErrorMsgIndexOutOfBounds(pos, _values.length)  );
// 	}*/
// 	
// 	/*void _setLength(size_t rcLength)
// 	{	foreach(ref fld; _fields)
// 		{	fld._setLength(rcLength);
// 			
// 		}
// 	}*/
// }

