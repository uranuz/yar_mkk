module webtank.datctrl.record;


import std.typetuple, std.typecons, std.stdio, std.conv;

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
			ValueType get()
			{	return _recordSet.getValue!(fieldName)(_recordKey);
			}
			
		}
		
		bool isNull(string fieldName)
		{	return _recordSet.isNull(fieldName, _recordKey);
		}
		
		bool isNullable(string fieldName)
		{	return _recordSet.isNullable(fieldName);
		}
	}
	
	
}


// class Record
// {	
// protected:
// 	RecordSet _recordSet;
// 	size_t _recKey;
// 	
// public:
// 	this(RecordSet recordSet, size_t recordKey)
// 	{	_recordSet = recordSet; _recKey = recordKey; }
// 	
// 	ICell opIndex(size_t index)  //Оператор получения ячейки по индексу поля
// 	{	return ( _recordSet.getField(index) )[_recKey];
// 	}
// 	ICell opIndex(string name)  //Оператор получения ячейки по имени поля
// 	{	return ( _recordSet.getField(name) )[_recKey];
// 	}
// 	
// 	//Операторы присвоения ячейке по индексу
// 	void opIndexAssign(string value, size_t index) 
// 	{	( _recordSet.getField(index) )[_recKey] = value;
// 	}
// 	void opIndexAssign(int value, size_t index) 
// 	{	( _recordSet.getField(index) )[_recKey] = value;
// 	}
// 	void opIndexAssign(bool value, size_t index) 
// 	{	( _recordSet.getField(index) )[_recKey] = value;
// 	}
// 	//Оператор присвоения ячейке по имени
// 	void opIndexAssign(string value, string name) 
// 	{	( _recordSet.getField(name) )[_recKey] = value;
// 	}
// 	void opIndexAssign(int value, string name) 
// 	{	( _recordSet.getField(name) )[_recKey] = value;
// 	}
// 	void opIndexAssign(bool value, string name) 
// 	{	( _recordSet.getField(name) )[_recKey] = value;
// 	}
// 	
// }
