module webtank.datctrl.record_format;

import std.stdio;

import webtank._version;

static if( isDatCtrlEnabled ) {

import std.typetuple, std.typecons, std.conv, std.json;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.db.database_field, webtank.common.serialization;

struct RecordFormat(Args...)
{	
	size_t keyFieldIndex = 0; //Номер основного ключевого поля (если их несколько)
	//Флаги для полей, показывающие может ли значение поля быть пустым (null)
	//(если значение = true) или нет (false)
	bool[string] nullableFlags; ///Флаги "обнулябельности"
	EnumFormat[string] enumFormats; ///Возможные значения для перечислимых полей
	
	///Метод получения типов полей (FieldType)
	static pure FieldType[] types() @property
	{	FieldType[] result;
		foreach( spec; _fieldSpecs )
			result ~= spec.fieldType;
		return result;
	}
	
	///Метод получения имён полей
	static pure string[] names() @property
	{	string[] result;
		foreach( spec; _fieldSpecs )
			result ~= spec.name;
		return result;
	}
	
	///Метод возыращает ассоциативный массив порядковых номеров
	///полей в формате, индексируемых по именам полей
	static pure size_t[string] indexes() @property
	{	size_t[string] result;
		foreach( i, spec; _fieldSpecs )
			result[spec.name] = i;
		return result;
	}
	
	//Внутреннее "хранилище" разобранной информации о полях записи
	//Не использовать извне!!!
	alias _parseRecordFormatArgs!Args _fieldSpecs;
	
	///АХТУНГ!!! ДАЛЕЕ ИДУТ СТРАШНЫЕ ШАБЛОННЫЕ ЗАКЛИНАНИЯ!!!
	
	///Шаблон возвращает кортеж имён полей отфильтрованных по типам FilterFieldTypes
	///Элементы кортежа FilterFieldTypes должны иметь тип FieldType
	template filterNamesByTypes(FilterFieldTypes...)
	{	alias _getFieldNameTuple!( _filterFieldSpecs!(_fieldSpecs).ByTypes!(FilterFieldTypes) ) filterNamesByTypes;
	}
	
	///Шаблон возвращает кортеж всех имён полей
	template tupleOfNames()
	{	alias _getFieldNameTuple!(_fieldSpecs) tupleOfNames;
	}
	
	///Шаблон для получения FieldType для поля с именем fieldName
	template getFieldType(string fieldName)
	{	alias _getFieldSpec!(fieldName, _fieldSpecs).fieldType getFieldType;
	}
	
	///Шаблон для получения FieldType для поля с индексом fieldIndex
	template getFieldType(size_t fieldIndex)
	{	alias _getFieldSpec!(fieldIndex, _fieldSpecs).fieldType getFieldType;
	}
	
	///Шаблон для получения типа значения поля с именем fieldName
	template getValueType(string fieldName)
	{	alias _getFieldSpec!(fieldName, _fieldSpecs).ValueType getValueType;
	}
	
	///Шаблон для получения типа значения поля с индексом fieldIndex
	template getValueType(size_t fieldIndex)
	{	alias _getFieldSpec!(fieldIndex, _fieldSpecs).ValueType getValueType;
	}
	
	///Шаблон для получения имени поля по индексу fieldIndex
	template getFieldName(size_t fieldIndex)
	{	alias _getFieldSpec!(fieldIndex, _fieldSpecs).name getFieldName;
	}
	
	///Шаблон получения порядкового номера поля в формате по имени fieldName
	template getFieldIndex(string fieldName)
	{	alias _getFieldIndex!(fieldName, 0, _fieldSpecs) getFieldIndex;
	}
	
	
}

///Формат для перечислимого поля
struct EnumFormat
{	
protected:
	string[int] _names;
	int[] _keys;

public:
	///Конструктор формата получает на входе карту соответсвия
	///ключей названиям элементов и параметр сортировки ключей 
	///(возрастающий по-умолчанию)
	this(immutable(string[int]) names, bool isAscendingOrder = true) immutable
	{	_names = names;
		import std.algorithm, std.exception;
		int[] keys = names.keys;
		
		if( isAscendingOrder )
			sort!("a < b")(keys);
		else
			sort!("a > b")(keys);
			
		_keys = assumeUnique(keys);
	}
	
	this( const(EnumFormat) format )
	{	foreach( key, name; format._names )
			_names[key] = name;
		
		_keys = format._keys.dup;
	}
	
	EnumFormat mutCopy() @property const
	{	return EnumFormat(this);
	}
	
	///Сериализует формат перечислимого типа в std.json
	JSONValue getStdJSON()
	{	JSONValue jValue;
		jValue.type = JSON_TYPE.OBJECT;
		
		//Словарь перечислимых значений (числовой ключ --> строковое имя)
		jValue["enum_n"] = JSONValue();
		jValue["enum_n"].type = JSON_TYPE.OBJECT;
		foreach( key, name; _names )
		{	string strKey = key.to!string;
			jValue["enum_n"].object[strKey].type = JSON_TYPE.STRING;
			jValue["enum_n"].object[strKey].str = name;
		}
		
		//Массив, определяющий порядок перечислимых значений
		jValue["enum_k"] = JSONValue();
		jValue["enum_k"].type = JSON_TYPE.ARRAY;
		foreach( key; _keys )
		{	jValue["enum_k"].array[key].type = JSON_TYPE.UINTEGER;
			jValue["enum_k"].array[key].uinteger = key;
		}
		return jValue;
	}
	
// 	EnumFormat dup() @property immutable
// 	{	return EnumFormat(this);
// 	}

	///Конструктор формата получает на входе карту соответсвия
	///ключей названиям элементов и массив ключей, определяющий
	///их порядок следования
// 	this(string[int] names, int[] keys)
// 	{	_names = names.idup;
// 		_keys = keys.idup;
// 	}
	
	///Оператор индексации по ключам для получения имени значения
	string opIndex(int key) const
	{	if( key in _names )
			return _names[key];
		else
			throw new Exception("Value " ~ key.to!string ~ " is not valid enum key!!!");
	}
	
	///Оператор in для проверки наличия ключа в наборе значений перечислимого типа
	//TODO: Разобраться как работает inout
	inout(string)* opBinaryRight(string op)(int key) inout if(op == "in")
	{	return ( key in _names );
	}
	
	///Возвращает набор названий значений перечислимого типа
	string[] names() @property const
	{	string[] result;
		foreach( key; _keys )
			result ~= _names[key];
		return result;
	}
	
	///Возвращает набор ключей для значений перечислимого типа
	int[] keys() @property const
	{	return _keys.dup;
	}
	
	///Оператор для обхода значений перечислимого типа через foreach
	///Первый параметр - имя (строка), второй - ключ (число)
	int opApply(int delegate(string name, int i) dg) const
	{	foreach( key; _keys )
		{	auto result = dg(names[key], key);
			if(result)
				return result;
		}
		return 0;
	}
	
	///Оператор для обхода значений перечислимого типа через foreach
	///в случае одного параметра (ключа)
	int opApply(int delegate(int i) dg)
	{	foreach( key; _keys )
		{	auto result = dg(key);
			if(result)
				return result;
		}
		return 0;
	}
}


///В шаблоне хранится соответсвие между именем и типом поля
template FieldSpec( FieldType ft, string s = null )
{	alias ft fieldType;
	alias GetFieldValueType!(ft) ValueType;
	alias s name;
}

//Шаблон разбирает аргументы и находит соответсвие имен и типов полей
//Результат: кортеж элементов FieldSpec
template _parseRecordFormatArgs(Args...)
{	static if( Args.length == 0 )
	{	alias TypeTuple!() _parseRecordFormatArgs;
	}
	else static if( is( typeof( Args[0] ) : FieldType ) )
	{	static if( is( typeof( Args[1] ) : string ) )
			alias TypeTuple!(FieldSpec!(Args[0 .. 2]), _parseRecordFormatArgs!(Args[2 .. $])) _parseRecordFormatArgs;
		else 
			alias TypeTuple!(FieldSpec!(Args[0]), _parseRecordFormatArgs!(Args[1 .. $])) _parseRecordFormatArgs;
	}
	else
	{	static assert(0, "Attempted to instantiate Tuple with an "
				~"invalid argument: "~ Args[0].stringof);
	}
}

template _getFieldNameTuple(FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		alias TypeTuple!() _getFieldNameTuple;
	else
		alias TypeTuple!( FieldSpecs[0].name, _getFieldNameTuple!(FieldSpecs[1..$]) ) _getFieldNameTuple;
}

//Получить из кортежа элементов типа FieldSpec нужный элемент по имени
template _getFieldSpec(string fieldName, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
	else static if( FieldSpecs[0].name == fieldName )
		alias FieldSpecs[0] _getFieldSpec;
	else
		alias _getFieldSpec!(fieldName, FieldSpecs[1 .. $]) _getFieldSpec;
}

//Получить из кортежа элементов типа FieldSpec нужный элемент по имени
template _getFieldSpec(size_t index, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with given index is not found in container!!!");
	else static if( index == 0 )
		alias FieldSpecs[0] _getFieldSpec;
	else
		alias _getFieldSpec!( index - 1, FieldSpecs[1 .. $]) _getFieldSpec;
}

template _getFieldIndex(string fieldName, size_t index, FieldSpecs...)
{	static if( FieldSpecs.length == 0 )
		static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
	else static if( FieldSpecs[0].name == fieldName )
		alias index _getFieldIndex;
	else 
		alias _getFieldIndex!(fieldName, index + 1 , FieldSpecs[1 .. $]) _getFieldIndex;
	
}

//Шаблон фильтрации кортежа элементов FieldSpec
template _filterFieldSpecs(FieldSpecs...)
{	//Фильтрация по типам полей
	//Элементы кортежа FilterFieldTypes должны иметь тип FieldType
	template ByTypes(FilterFieldTypes...)
	{	static if( FieldSpecs.length == 0 )
			alias TypeTuple!() ByTypes;
		else
			alias TypeTuple!(
				//Вызов фильтации для первого FieldSpec по набору FilterFieldTypes (типов полей)
				_filterFieldSpec!(FieldSpecs[0], FilterFieldTypes),
				
				//Вызов для остальных FieldSpecs
				_filterFieldSpecs!(FieldSpecs[1..$]).ByTypes!(FilterFieldTypes)
			) ByTypes;
	}
	
}

//Фильтрация одного элемента FieldSpec по набору типов полей
//Элементы кортежа FilterFieldTypes должны иметь тип FieldType
template _filterFieldSpec(alias FieldSpec, FilterFieldTypes...)
{	
	static if( FilterFieldTypes.length == 0 )
		alias TypeTuple!() _filterFieldSpec;
	else
	{	static if( FilterFieldTypes[0] == FieldSpec.fieldType )
			alias FieldSpec _filterFieldSpec;
		else
			alias _filterFieldSpec!(FieldSpec, FilterFieldTypes[1..$]) _filterFieldSpec;
	}
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