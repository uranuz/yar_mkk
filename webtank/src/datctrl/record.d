module webtank.datctrl.record;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.datctrl.record_set, webtank.datctrl.record_format, webtank.db.database_field;

interface IBaseRecord
{	string getStr(string fieldName, string defaultValue);
	bool isNull(string fieldName);
	bool isNullable(string fieldName);
	size_t length() @property;
}

template Record(alias RecFormat)
{	
	
	class Record: IBaseRecord
	{
	public:
		alias RecordSet!RecFormat RecSet;
		alias RecFormat RecordFormatType;
		
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
			alias getFieldSpec!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
			ValueType get()
			{	return _recordSet.get!(fieldName)(_recordKey);
			}

			ValueType get(ValueType defaultValue)
			{	return _recordSet.get!(fieldName)(_recordKey, defaultValue);
			}
			
		}
		
		override {
			string getStr(string fieldName, string defaultValue = null)
			{	return _recordSet.getStr( fieldName, _recordKey, defaultValue );
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
		
		} //override
		
		size_t keyFieldIndex() @property
		{	return _recordSet.keyFieldIndex();
		}
	}
}


} //static if( isDatCtrlEnabled )
