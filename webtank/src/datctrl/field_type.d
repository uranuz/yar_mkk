module webtank.datctrl.field_type;
///Модуль по работе с типами полей

import std.conv;

enum FieldType { Str, Int, Bool, IntKey, Text, Enum /*, Date*/  };

///Строковые значения, которые трактуются как false при преобразовании
///типов. Любые другие трактуются как true
immutable(string[]) _logicTrueValues = 
		 [`true`, `t`, `yes`, `y`, `истина`, `и`, `да`, `д`];

///Строка ошибки времени компиляции - что, мол, облом
immutable(string) _notImplementedErrorMsg = ` Данный тип не реализован: `;

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
	else
		static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
}

///Преобразование из различных настоящих типов в другой реальный
///тип, который соотвествует семантическому типу поля, 
///указанному в параметре шаблона FieldT
template fldConv(FieldType FieldT)
{	alias GetFieldValueType!(FieldT) ValueT;
	// int --> GetFieldValueType!(FieldT)
	ValueT fldConv( int value )
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
			static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// string --> GetFieldValueType!(FieldT)
	ValueT fldConv( string value )
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
		else
			static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// bool --> GetFieldValueType!(FieldT)
	ValueT fldConv( bool value )
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
			static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
	// size_t --> GetFieldValueType!(FieldT)
	ValueT fldConv( size_t value )
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
			static assert( 0, _notImplementedErrorMsg ~ FieldT.to!string );
		}  //with( FieldType )
		assert(0);
	}
	
}