module webtank.datctrl.record;

import std.stdio;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv, std.json;

import   webtank.datctrl.data_field, webtank.datctrl.record_set, webtank.datctrl.record_format, webtank.db.database_field, webtank.common.serialization;

interface IBaseRecord
{	string getStr(string fieldName, string defaultValue);
	bool isNull(string fieldName);
	bool isNullable(string fieldName);
	size_t length() @property;
}

///Класс реализует работу с записью
template Record(alias RecordFormatT)
{	
	
	class Record: IBaseRecord
	{
		///Тип формата для записи
		alias RecordFormatT FormatType;
		
		private alias RecordSet!FormatType RecordSetType;
		
	protected:
		RecordSetType _recordSet;
		size_t _recordKey;
	
	public:
		
		///Сериализаци записи в std.json
		JSONValue getStdJSON()
		{	JSONValue jValue = _recordSet.getStdJSONFormat();
			
			jValue.object["d"] = 
				_recordSet.getStdJSONDataAt( _recordSet.getRecordIndex(_recordKey) );
			
			jValue.object["t"] = JSONValue();
			jValue.object["t"].type = JSON_TYPE.STRING;
			jValue.object["t"].str = "record";

			return jValue;
		}
		
		this(RecordSetType recordSet, size_t recordKey)
		{	_recordSet = recordSet;
			_recordKey = recordKey;
		}
		
		///Методы получения значения ячейки данных по имени поля
		template get(string fieldName)
		{	
			alias FormatType.getValueType!(fieldName) ValueType;
			ValueType get()
			{	return _recordSet.get!(fieldName)(_recordKey);
			}

			ValueType get(ValueType defaultValue)
			{	return _recordSet.get!(fieldName)(_recordKey, defaultValue);
			}
		}
		
		///Метод получения формата для перечислимого типа
		///Значения отсортированы по возрастанию
		auto getEnumFormat(string fieldName)()
		{	writeln("_recordSet.getEnumFormat!(fieldName)()", _recordSet.getEnumFormat!(fieldName)());
			return _recordSet.getEnumFormat!(fieldName)();
		}
		
		override {
			///Получение "сырого" строкового представления ячейки данных по имени поля
			string getStr(string fieldName, string defaultValue = null)
			{	return _recordSet.getStr( fieldName, _recordKey, defaultValue );
			}
			
			///Возвращает true, если значение ячейки данных с именем fieldName пустое.
			///В противном случае возвращает false.
			bool isNull(string fieldName)
			{	return _recordSet.isNull(fieldName, _recordKey);
			}
			
			bool isNullable(string fieldName)
			{	return _recordSet.isNullable(fieldName);
			}
			
			///Возвращает количество ячеек данных в записи
			size_t length() @property
			{	return FormatType.tupleOfNames!().length;
			}
		
		} //override
		
		///Порядковый номер ключевого поля данных
		size_t keyFieldIndex() @property
		{	return _recordSet.keyFieldIndex();
		}
	}
}


} //static if( isDatCtrlEnabled )
