module webtank.datctrl.field_type;
///Модуль по работе с типами полей

import std.conv, std.datetime;

enum FieldType { Str, Int, Bool, IntKey, Date, Enum, Text };

///Строковые значения, которые трактуются как false при преобразовании
///типов. Любые другие трактуются как true
immutable(string[]) _logicTrueValues = 
		 [`true`, `t`, `yes`, `y`, `истина`, `и`, `да`, `д`];

///Строка ошибки времени компиляции - что, мол, облом
immutable(string) _notImplementedErrorMsg = `This conversion is not implemented: `;

///Шаблон для получения реального типа поля по перечислимому 
///значению семантического типа поля
template GetFieldValueType(FieldType FieldT) 
{	static if( FieldT == FieldType.Int || FieldT == FieldType.Enum )
		alias int GetFieldValueType;
	else static if( FieldT == FieldType.Str )
		alias string GetFieldValueType;
	else static if( FieldT == FieldType.Bool )
		alias bool GetFieldValueType;
	else static if( FieldT == FieldType.IntKey )
		alias size_t GetFieldValueType;
	else static if( FieldT == FieldType.Date )
		alias std.datetime.Date GetFieldValueType;
	else
		static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
}

///Преобразование из различных настоящих типов в другой реальный
///тип, который соотвествует семантическому типу поля, 
///указанному в параметре шаблона FieldT
auto fldConv(FieldType FieldT, S)( S value )
{	
	import std.traits;
	// целые числа --> GetFieldType!(FieldT)
	static if( isIntegral!(S) )
	{	with( FieldType ) {
		//Стандартное преобразование
		static if( FieldT == Int || FieldT == Str || FieldT == IntKey )
		{	return value.to!( GetFieldValueType!FieldT ); }
		else static if( FieldT == Bool ) //Для уверенности
		{	return ( value == 0 ) ? false : true ; }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// строки --> GetFieldType!(FieldT)
	else static if( isSomeString!(S) )
	{	with( FieldType ) {
		//Стандартное преобразование
		static if( FieldT == Int || FieldT == Str || FieldT == IntKey )
		{	return value.to!( GetFieldValueType!FieldT ); }
		else static if( FieldT == Bool )
		{	import std.string;
			foreach(logVal; _logicTrueValues) 
				if ( logVal == toLower( strip( value ) ) ) return true;
			return false;
		}
		else static if( FieldT == Date )
		{	return std.datetime.Date.fromISOExtString(value); }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// bool --> GetFieldType!(FieldT)
	else static if( is( S : bool ) )
	{	with( FieldType ) {
		static if( FieldT == Int || FieldT == IntKey || FieldT == Enum )
		{	return ( value ) ? 1 : 0; }
		else static if( FieldT == Str )
		{	return ( value ) ? "да" : "нет"; }
		else static if( FieldT == Bool )
		{	return value; }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}

}


//Возвращает true если данный тип поля является типом ключевого поля
template isKeyFieldType(FieldType fieldType)
{	static if( fieldType == FieldType.IntKey )
		enum isKeyFieldType = true;
	else
		enum isKeyFieldType = false;
}