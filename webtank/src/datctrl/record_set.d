module webtank.datctrl.record_set;

import std.array;
import std.conv;

//import std.stdio;

import webtank.datctrl.data_field, webtank.datctrl.record, webtank.datctrl.record_format;


// template record!(alias RecFormat)
// {	
// 	alias 
// 	
// 	class RecordSet
// 	{	
// 		
// 		
// 	}
// 	
// 	
// }

class RecordSet   //: IRecordSet
{	
protected:
	IField[] _fields;
	size_t[string] _indexes;
	//string[] _names;

public:
	Record opIndex(size_t key)  //Оператор получения записи по индексу
	{	//if( index < _fields[0].length )
			return new Record(this, key);
		//else return null;
	}
	
	Record front() @property
	{	return new Record( this, _fields[0]._frontKey );
	}
	
	void popFront()
	{	_fields[0].popFront(); }
	
	bool empty() @property
	{	return _fields[0].empty;
	}
	
	size_t _frontKey() @property
	{	return _fields[0]._frontKey; }
	
	//this(IRecordFormat format)
	
	IField getField(string name)
	{	if( (_indexes !is null) && (name in _indexes) )
			return _fields[ _indexes[name] ];
		else return null;
	}
	
	IField getField(size_t index)
	{	if( index < _fields.length )
			return _fields[index];
		else return null;
	}

	size_t recordCount() @property
	{	if( _fields.length > 0 ) 
			return _fields[0].length;
		else  return 0;
	}
	
	size_t fieldCount() @property
	{	return _fields.length; }
	
	bool hasField(string name)
	{	return (name in _indexes) ? true : false;
	}
	
	void addField(IField field)
	{	size_t count = _fields.length;
		_indexes[field.name] = count;
		_fields ~= field;
	}
	
	/*void _insertField(IField field, size_t pos)
	{	if( pos < _fields.length )
			_fields.insertInPlace(pos, field);
		//else
		//	assert( _getErrorMsgIndexOutOfBounds(pos, _values.length)  );
	}*/
	
	/*void _setLength(size_t rcLength)
	{	foreach(ref fld; _fields)
		{	fld._setLength(rcLength);
			
		}
	}*/
}

