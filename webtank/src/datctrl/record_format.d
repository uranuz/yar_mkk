module webtank.datctrl.new_record;


import std.typetuple, std.typecons, std.stdio, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database_field;

struct RecordFormat(Args...)
{	alias TypeTuple!Args templateArgs;
	alias parseFieldSpecs!Args fieldSpecs;
	
	static FieldType[] types() @property
	{	FieldType[] result;
		foreach( i, spec ; fieldSpecs)
		{	result ~= spec.fieldType;
		}
			
		return result;
	}
	
	static string[] names() @property
	{	string[] result;
		foreach( i, spec ; fieldSpecs)
			result ~= spec.name;
		return result;
	}
	
	bool[] nullableFlags;
	//EnumValuesType[size_t] enumValues;
	
}

//В шаблоне хранится соответсвие между именем и типом поля
template FieldSpec( FieldType ft, string s = null )
{	alias ft fieldType;
	alias GetFieldValueType!(ft) valueType;
	alias s name;
}

//Шаблон разбирает аргументы и находит соответсвие имен и типов полей
//Результат: кортеж элементов FieldSpec
template parseFieldSpecs(Args...)
{	static if( Args.length == 0 )
	{	alias TypeTuple!() parseFieldSpecs;
	}
	else static if( is( typeof( Args[0] ) : FieldType ) )
	{	static if( is( typeof( Args[1] ) : string ) )
			alias TypeTuple!(FieldSpec!(Args[0 .. 2]), parseFieldSpecs!(Args[2 .. $])) parseFieldSpecs;
		else 
			alias TypeTuple!(FieldSpec!(Args[0]), parseFieldSpecs!(Args[1 .. $])) parseFieldSpecs;
	}
	else
	{	static assert(0, "Attempted to instantiate Tuple with an "
				~"invalid argument: "~ Args[0].stringof);
	}
}

//Получить из кортежа элементов типа FieldSpec нужный элемент по имени
template getFieldSpecByName(string fieldName, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
	else static if( FieldSpecs[0].name == fieldName )
		alias FieldSpecs[0] getFieldSpecByName;
	else
		alias getFieldSpecByName!(fieldName, FieldSpecs[1 .. $]) getFieldSpecByName;
}

//По кортежу элементов типа FieldSpec строит кортеж полей
template getDatabaseFieldTuple(FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() getDatabaseFieldTuple;
	else 
		alias TypeTuple!(DatabaseField!(FieldSpecs[0].fieldType), getDatabaseFieldTuple!(FieldSpecs[1 .. $])) getDatabaseFieldTuple;
}

template getValueTypeTuple(FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() getValueTypeTuple;
	else 
		alias TypeTuple!(FieldSpecs[0].valueType, getValueTypeTuple!(FieldSpecs[1 .. $])) getValueTypeTuple;
}
	
	
template RecordSet(alias RecFormat)
{
	alias Tuple!( getDatabaseFieldTuple!(RecFormat.fieldSpecs) ) fieldTupleType;
	
	class RecordSet
	{	
	protected:
		fieldTupleType _fields;
		
		
	public:
	
		template _setField(string fieldName)
		{	
			alias getFieldSpecByName!(fieldName, RecFormat.fieldSpecs).fieldType fieldType;
			alias IField!(fieldType) FieldIface;
			void _setField(FieldIface field)
			{	
				
			}
		
		
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




void main()
{	
	alias FieldType ft;
	auto format = RecordFormat!(ft.IntKey, "Количество", ft.Int, "Цена", ft.Str, "Название", ft.Bool, "Условие")
		([true, true, true, false]);
	
	getFieldSpecByName!("Количество", format.fieldSpecs).valueType var;
	writeln( typeid( var ).to!string );
	writeln( format.types() );
	writeln( format.names() );
	writeln( format.nullableFlags );
	
	
	writeln( typeid( getDatabaseFieldTuple!(format.fieldSpecs) ).to!string  );
	alias  getDatabaseFieldTuple!(format.fieldSpecs)[2] DBFieldType;
	auto field = new DBFieldType;
	writeln( typeid( field ).to!string  );
	writeln( field.isNullable() );
	
	alias RecordSet!format RSType;
	
	writeln( typeid( RSType ).to!string  );
}