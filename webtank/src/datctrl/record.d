module webtank.datctrl.record;

import webtank.datctrl.field_type;
import webtank.datctrl.data_cell;
import webtank.datctrl.record_set;

struct RecordFormat
{	//alias EnumValuesType string[int];
	
	FieldType[] types;
	string[] names;
	bool[] nullableFlags;
	//EnumValuesType[size_t] enumValues;
}

class Record
{	
protected:
	RecordSet _recordSet;
	size_t _recKey;
	
public:
	this(RecordSet recordSet, size_t recordKey)
	{	_recordSet = recordSet; _recKey = recordKey; }
	
	ICell opIndex(size_t index)  //Оператор получения ячейки по индексу поля
	{	return ( _recordSet.getField(index) )[_recKey];
	}
	ICell opIndex(string name)  //Оператор получения ячейки по имени поля
	{	return ( _recordSet.getField(name) )[_recKey];
	}
	
	//Операторы присвоения ячейке по индексу
	void opIndexAssign(string value, size_t index) 
	{	( _recordSet.getField(index) )[_recKey] = value;
	}
	void opIndexAssign(int value, size_t index) 
	{	( _recordSet.getField(index) )[_recKey] = value;
	}
	void opIndexAssign(bool value, size_t index) 
	{	( _recordSet.getField(index) )[_recKey] = value;
	}
	//Оператор присвоения ячейке по имени
	void opIndexAssign(string value, string name) 
	{	( _recordSet.getField(name) )[_recKey] = value;
	}
	void opIndexAssign(int value, string name) 
	{	( _recordSet.getField(name) )[_recKey] = value;
	}
	void opIndexAssign(bool value, string name) 
	{	( _recordSet.getField(name) )[_recKey] = value;
	}
	
}