module webtank.datctrl.record_format;


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

//Получить из кортежа элементов типа FieldSpec нужный элемент по имени
template getFieldSpecByIndex(size_t index, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with given index is not found in container!!!");
	else static if( index == 0 )
		alias FieldSpecs[0] getFieldSpecByIndex;
	else
		alias getFieldSpecByIndex!( index - 1, FieldSpecs[1 .. $]) getFieldSpecByIndex;
}

//По кортежу элементов типа FieldSpec строит кортеж полей
template getTupleOfByFieldSpec(alias Element, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() getTupleOfByFieldSpec;
	else 
		alias TypeTuple!(Element!(FieldSpecs[0].fieldType), getTupleOfByFieldSpec!(Element, FieldSpecs[1 .. $])) getTupleOfByFieldSpec;
}

//Получаем кортеж фактических типов значений по FieldSpec
template getValueTypeTuple(FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() getValueTypeTuple;
	else 
		alias TypeTuple!(FieldSpecs[0].valueType, getValueTypeTuple!(FieldSpecs[1 .. $])) getValueTypeTuple;
}

template _workGetFieldSpecIndex(string fieldName, size_t index, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
	else static if( FieldSpecs[0].name == fieldName )
		alias index _workGetFieldSpecIndex;
	else 
		alias _workGetFieldSpecIndex!(fieldName, index + 1 , FieldSpecs[1 .. $]) _workGetFieldSpecIndex;
	
}

//Получение индекса элемента из кортежа FieldSpec по имени
template getFieldSpecIndex(string fieldName, FieldSpecs...)
{	alias _workGetFieldSpecIndex!(fieldName, 0 , FieldSpecs) getFieldSpecIndex;
}

//Получение списка индексов всех ключевых полей
size_t[] getKeyFieldIndexes(FieldSpecs...)()
{	size_t[] result;
	foreach( i, spec; FieldSpecs )
	{	if( spec.fieldType == FieldType.IntKey )
		{	result ~= i;
		}
	}
	return result;
}

