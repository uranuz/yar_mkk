module webtank.datctrl.record_format;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database_field;

struct RecordFormat(Args...)
{	alias TypeTuple!Args templateArgs;
	alias parseFieldSpecs!Args fieldSpecs;
	
	static pure FieldType[] types() @property
	{	FieldType[] result;
		foreach( spec; fieldSpecs )
			result ~= spec.fieldType;
		return result;
	}
	
	static pure string[] names() @property
	{	string[] result;
		foreach( spec; fieldSpecs )
			result ~= spec.name;
		return result;
	}
	
	static pure size_t[string] indexes() @property
	{	size_t[string] result;
		foreach( i, spec; fieldSpecs )
			result[spec.name] = i;
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
template getFieldSpec(string fieldName, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
	else static if( FieldSpecs[0].name == fieldName )
		alias FieldSpecs[0] getFieldSpec;
	else
		alias getFieldSpec!(fieldName, FieldSpecs[1 .. $]) getFieldSpec;
}

//Получить из кортежа элементов типа FieldSpec нужный элемент по имени
template getFieldSpec(size_t index, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with given index is not found in container!!!");
	else static if( index == 0 )
		alias FieldSpecs[0] getFieldSpec;
	else
		alias getFieldSpec!( index - 1, FieldSpecs[1 .. $]) getFieldSpec;
}

//По кортежу элементов типа FieldSpec строит кортеж полей
template getTupleTypeOf(alias Element, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() getTupleTypeOf;
	else 
		alias TypeTuple!(Element!(FieldSpecs[0].fieldType), getTupleTypeOf!(Element, FieldSpecs[1 .. $])) getTupleTypeOf;
}

//Получаем кортеж фактических типов значений по FieldSpec
template getValueTypeTuple(FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() getValueTypeTuple;
	else 
		alias TypeTuple!(FieldSpecs[0].valueType, getValueTypeTuple!(FieldSpecs[1 .. $])) getValueTypeTuple;
}

template _workGetFieldIndex(string fieldName, size_t index, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
	else static if( FieldSpecs[0].name == fieldName )
		alias index _workGetFieldIndex;
	else 
		alias _workGetFieldIndex!(fieldName, index + 1 , FieldSpecs[1 .. $]) _workGetFieldIndex;
	
}

//Получение индекса элемента из кортежа FieldSpec по имени
template getFieldIndex(string fieldName, FieldSpecs...)
{	alias _workGetFieldIndex!(fieldName, 0 , FieldSpecs) getFieldIndex;
}

//Получение списка индексов всех ключевых полей
size_t[] getKeyFieldIndexes(FieldSpecs...)()
{	size_t[] result;
	foreach( i, spec; FieldSpecs )
		if( spec.fieldType == FieldType.IntKey )
			result ~= i;
	return result;
}


} //static if( isDatCtrlEnabled )