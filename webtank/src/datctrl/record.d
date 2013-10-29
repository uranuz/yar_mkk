module webtank.datctrl.record;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.datctrl.record_set, webtank.datctrl.record_format, webtank.db.database_field, webtank.common.serialization;

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
		
		JSONValue getStdJSON()
		{	JSONValue jValue = _format.getStdJSON();
			
			jValue.object["d"] = _recordSet.serializeDataAt(_recordKey);
			jValue.object["t"] = JSONValue();
			jValue.object["t"].type = JSON_TYPE.STRING;
			jValue.object["t"].str = "record";

			return jValue;
		}
		
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
		
		//Функция получения формата для перечислимого типа
		//Значения отсортированы по возрастанию
		auto getEnum(string fieldName)()
		{	return _recordSet.getEnum!(fieldName)();
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
