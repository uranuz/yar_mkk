module webtank.datctrl.record;

import std.typetuple, std.typecons, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.datctrl.record_set, webtank.datctrl.record_format, webtank.db.database_field;


template Record(alias RecFormat)
{	
	alias RecordSet!RecFormat RecSet;
	
	class Record
	{
	protected:
		RecSet _recordSet;
		size_t _recordKey;
	
	public:
		this(RecSet recordSet, size_t recordKey)
		{	_recordSet = recordSet;
			_recordKey = recordKey;
		}
		
		template get(string fieldName)
		{	
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
			ValueType get() @property
			{	return _recordSet.get!(fieldName)(_recordKey);
			}
			
		}
		
		template get(string fieldName)
		{	
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
			ValueType get(ValueType defaultValue)
			{	return _recordSet.get!(fieldName)(_recordKey, defaultValue);
			}
			
		}
		
		bool isNull(string fieldName)
		{	return _recordSet.isNull(fieldName, _recordKey);
		}
		
		bool isNullable(string fieldName)
		{	return _recordSet.isNullable(fieldName);
		}
		
		size_t length() @property
		{	return RecFormat.fieldSpecs.length;
			
		}
	}
}

