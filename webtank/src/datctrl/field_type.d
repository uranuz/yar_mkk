module webtank.datctrl.field_type;
///Модуль по работе с типами полей

import std.conv, std.datetime;

enum FieldType { Str, Int, Bool, IntKey, Date, Text, Enum };

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
{	// int --> GetFieldType!(FieldT)
	static if( is( S : int ) )
	{	with( FieldType ) {
		static if( FieldT == Int /*|| FieldT == Enum*/ )
		{	return value; }
		else static if( FieldT == Str )
		{	return value.to!string; }
		else static if( FieldT == Bool )
		{	return ( value == 0 ) ? false : true ; }
		else static if( FieldT == IntKey )
		{	return value.to!size_t; }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// string --> GetFieldType!(FieldT)
	else static if( is( S : string ) )
	{	with( FieldType ) {
		static if( FieldT == Int /*|| FieldT == Enum*/ )
		{	return value.to!int; }
		else static if( FieldT == Str )
		{	return value; }
		else static if( FieldT == Bool )
		{	import std.string;
			foreach(logVal; _logicTrueValues) 
				if ( logVal == toLower( strip( value ) ) ) return true;
			return false;
		}
		else static if( FieldT == IntKey )
		{	return value.to!size_t; }
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
		static if( FieldT == Int /*|| FieldT == Enum*/ )
		{	return ( value ) ? 1 : 0; }
		else static if( FieldT == Str )
		{	return ( value ) ? "да" : "нет"; }
		else static if( FieldT == Bool )
		{	return value; }
		else static if( FieldT == IntKey )
		{	return ( value ) ? 1 : 0; }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// size_t --> GetFieldType!(FieldT)
	else static if( is( S : size_t ) )
	{	with( FieldType ) {
		static if( FieldT == Int /*|| FieldT == Enum*/ )
		{	return value.to!int; }
		else static if( FieldT == Str )
		{	return value.to!string; }
		else static if( FieldT == Bool )
		{	return ( value == 0 ) ? false : true ; }
		else static if( FieldT == IntKey )
		{	return value; }
		else
			static assert( 0, _notImplementedErrorMsg ~ typeof(value).stringof ~ " --> " ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
}