module webtank.datctrl.new_record;


import std.typetuple, std.typecons, std.stdio, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database_field;

struct RecordFormat(Args...)
{	alias TypeTuple!(Args) tplArgs;
	
	bool[] nullableFlags;
	//EnumValuesType[size_t] enumValues;
	
}


template RecordTraits(Args...)
{	
	template parseFieldSpecs(Specs...)
	{	static if( Specs.length == 0 )
		{	
// 			static assert(0, "Запись должна содержать хотя бы одно поле!");
			alias TypeTuple!() parseFieldSpecs;
		}
		else static if( is( typeof( Specs[0] ) : FieldType ) )
		{	static if( is( typeof( Specs[1] ) : string ) )
			{	alias TypeTuple!(FieldSpec!(Specs[0 .. 2]), parseFieldSpecs!(Specs[2 .. $])) parseFieldSpecs;
			}
			else 
			{
				alias TypeTuple!(FieldSpec!(Specs[0]), parseFieldSpecs!(Specs[1 .. $])) parseFieldSpecs;
			}

		}
		else
		{	static assert(0, "Attempted to instantiate Tuple with an "
					~"invalid argument: "~ Specs[0].stringof);
		}
		
	}
	
	template FieldSpec( FieldType ft, string s = null )
	{	alias ft fieldType;
		alias GetFieldValueType!(ft) valueType;
		alias s name;
	}
	
	alias parseFieldSpecs!Args fieldSpecs;
	
	template generalGetFieldSpecByName(string fieldName, FldSpecs...)
	{	static if( FldSpecs.length == 0 )
		{	static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
		}
		else static if( FldSpecs[0].name == fieldName )
		{	alias FldSpecs[0] generalGetFieldSpecByName;
		}
		else
		{	alias generalGetFieldSpecByName!(fieldName, FldSpecs[1 .. $]) generalGetFieldSpecByName;
		}
	}
	
	
	template getFieldSpecByName(string fieldName)
	{	alias generalGetFieldSpecByName!(fieldName, fieldSpecs) getFieldSpecByName;
	}
	
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
	
	template generalGetFieldTuple(FieldSpecs...)
	{	static if( FieldSpecs.length == 0 )
		{	alias TypeTuple!() generalGetFieldTuple;
		}
		else 
		{	alias TypeTuple!(DatabaseField!(FieldSpecs[0].fieldType), generalGetFieldTuple!(FieldSpecs[1 .. $])) generalGetFieldTuple;
		}
	}
	
	template getFieldTuple()
	{	alias TypeTuple!(generalGetFieldTuple!(fieldSpecs)) getFieldTuple;
		
	}
	
	
// 	class RecordSet
// 	{	
// 		
// 		
// 	}
// 	
// 	class Record
// 	{	
// 		
// 	}
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
	
	format.getFieldSpecByName!("Количество").valueType var;
	writeln( typeid( var ).to!string );
	writeln( format.types() );
	writeln( format.names() );
	writeln( format.nullableFlags );
	
	
	writeln( typeid( format.getFieldTuple!() ).to!string  );
	alias  format.getFieldTuple!()[2] DBFieldType;
	auto field = new DBFieldType;
	writeln( typeid( field ).to!string  );
// 	writeln( field.isNullable() );
}