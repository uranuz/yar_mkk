module webtank.datctrl.record_format;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv, std.json;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database_field, webtank.common.serialization;

struct RecordFormat(Args...)
{	alias TypeTuple!Args templateArgs;
	alias parseFieldSpecs!Args fieldSpecs;
	
	///Метод получения типов полей (FieldType)
	static pure FieldType[] types() @property
	{	FieldType[] result;
		foreach( spec; fieldSpecs )
			result ~= spec.fieldType;
		return result;
	}
	
	///Метод получения имён полей
	static pure string[] names() @property
	{	string[] result;
		foreach( spec; fieldSpecs )
			result ~= spec.name;
		return result;
	}
	
	///Метод возыращает ассоциативный массив порядковых номеров
	///полей в формате, индексируемых по именам полей
	static pure size_t[string] indexes() @property
	{	size_t[string] result;
		foreach( i, spec; fieldSpecs )
			result[spec.name] = i;
		return result;
	}
	
	///Метод сериализует формат в std.json
	JSONValue getStdJSON()
	{	JSONValue jValue = void;
		jValue.type = JSON_TYPE.OBJECT;
		jValue.object["kfi"] = JSONValue();
		jValue.object["kfi"].type = JSON_TYPE.UINTEGER;
		jValue.object["kfi"].uinteger = keyFieldIndex;
		
		//Образуем JSON-массив описаний полей
		JSONValue fieldsJSON = void;
		fieldsJSON.type = JSON_TYPE.ARRAY;
		foreach( spec; fieldSpecs )
		{	JSONValue fldJSON;
			fldJSON.type = JSON_TYPE.OBJECT;
			
			fldJSON.object["n"] = JSONValue(); 
			fldJSON.object["t"] = JSONValue();
			fldJSON["n"].str = spec.name;
			fldJSON["t"].str = spec.fieldType.to!string;
			fieldsJSON.array ~= fldJSON; //Добавляем описание поля
		}
		//Добавляем массив описаний полей к результату
		jValue.object["f"] = fieldsJSON;
		return jValue;
	}
	
	size_t keyFieldIndex = 0; //Номер основного ключевого поля (если их несколько)
	//Флаги для полей, показывающие может ли значение поля быть пустым (null)
	//(если значение = true) или нет (false)
	bool[string] nullableFlags; //Флаги "обнулябельности"
	string[int][string] enumValues; //Возможные значения для перечислимых полей
	
}

class EnumFormat
{	
protected:
	string[int] _map;
	string[] _names;
	int[] _values;


public:
	this(string[int] map)
	{	_map = map.dup;
		import std.algorithm;
		_values = _map.keys;
		sort!("a < b")(_values);
		
		foreach( i; _values )
			_names ~= _map[i];
	}
	
	string getName(int value)
	{	if( value in _map )
			return _map[value];
		else
			throw new Exception("Value " ~ value.to!string ~ " is not valid enum value!!!");
	}
	
	//Определяем оператор in для класса
	//TODO: Разобраться как работает inout
// 	inout(string)* opBinaryRight(string op)(int value) inout if(op == "in")
// 	{	return ( value in _map );
// 	}

	bool hasValue(int value)
	{	if( value in _map )
			return true;
		else
			return false;
	}
	
	string[] names() @property
	{	return _names.dup;
	}
	
	int[] values() @property
	{	return _values.dup;
	}


	int opApply(int delegate(ref string name, ref int i) dg)
	{	for( size_t i = 0; i < values.length; i++ )
		{	auto result = dg(names[i], values[i]);
			if(result)
				return result;
		}
		
		return 0;
	}
	
	int opApply(int delegate(ref int i) dg)
	{	for( size_t i = 0; i < values.length; i++ )
		{	auto result = dg(values[i]);
			if(result)
				return result;
		}
		return 0;
	}
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