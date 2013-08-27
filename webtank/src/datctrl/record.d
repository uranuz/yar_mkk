module webtank.datctrl.record;


import std.typetuple, std.typecons, std.stdio, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database_field;


// template Record(alias RecFormat)
// {	
// 	
// 	
// 	class Record
// 	{
// 		
// 		
// 		template get(string fieldName)
// 		{	
// 			
// 			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).valueType ValueType;
// 			ValueType get()
// 			{	
// 				
// 				
// 			}
// 			
// 		}
// 		
// 		
// 		
// 	}
// 	
// 	
// }


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
