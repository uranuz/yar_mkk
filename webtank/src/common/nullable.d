module webtank.common.nullable;

import std.stdio;

///Returns true if T is nullable type
template isNullable(T)
{	enum bool isNullable = __traits( compiles, { bool aaa = T.init is null; } );
}

///Шаблон, возвращает true, если N является Nullable или NullableRef
template isStdNullable(N)
{	import std.typecons;
	static if( is( N == NullableRef!(TL1), TL1... ) )
		enum bool isStdNullable = true;
	else static if( is( N == Nullable!(TL2), TL2... ) )
		enum bool isStdNullable = true;
	else
		enum bool isStdNullable = false;
}

///Шаблон возвращает базовый тип для Nullable или NullableRef
template getStdNullableType(N)
{	import std.typecons, std.traits;
	static if( is( N == NullableRef!(TL2), TL2... ) )
		alias TL2[0] getStdNullableType;
	else static if( is( N == Nullable!(TL2), TL2... ) )
		alias TL2[0] getStdNullableType;
	else
		static assert (0, `Type ` ~ fullyQualifiedName!(N) ~ ` can't be used as Nullable type!!!` );
}

template isWebtankNullable(N)
{	enum bool isWebtankNullable = is( N == Nullable!(T), T ) ;
}

unittest
{	
	interface Vasya {}
	
	class Petya {}
	
	struct Vova {}
	
	alias void function(int) FuncType;
	alias bool delegate(string, int) DelType;
	
	//Check that these types are nullable
	assert( isNullable!Vasya );
	assert( isNullable!Petya );
	assert( isNullable!(string) );
	assert( isNullable!(int*) );
	assert( isNullable!(string[string]) );
	assert( isNullable!(FuncType) );
	assert( isNullable!(DelType) );
	assert( isNullable!(dchar[7]*) );
	
	//Check that these types are not nullable
	assert( !isNullable!Vova );
	assert( !isNullable!(double) );
	assert( !isNullable!(int[8]) );
	assert( !isNullable!(double) );
}

// private struct NullableTag { }
// 
// 
// template Nullable(T)
// {
// 	static if (isNullable!(T)) { alias T Nullable; }
// 	else
// 	{
// 		struct Nullable
// 		{
// 			// To tell if something is Nullable
// 			private alias .NullableTag NullableTag;
// 			private T _value;
// 			private bool _hasValue;
// 
// 			public this(A)(auto ref A value)
// 				inout /+pure @safe nothrow+/
// 			{
// 				this._value = value;
// 				this._hasValue = true;
// 			}
// 
// 			public this(A : typeof(null))(A)
// 				inout /+pure @safe nothrow+/ { }
// 
// 			public @property ref const(bool) hasValue()
// 				const /+pure @safe nothrow+/
// 			{ return this._hasValue; }
// 
// 			public @property ref inout(T) value()
// 				inout /+pure @safe+/
// 			{ return *(this._hasValue ? &this._value : null); }
// 
// 			
// 
// 			public bool opEquals(RHS)(scope RHS rhs)
// 				const /+pure @safe nothrow+/
// 				if (!is(RHS.NullableTag == NullableTag))
// 			{ return this.hasValue && this._value == rhs; }
// 
// 			public bool opEquals(RHS)(scope RHS rhs)
// 				const /+pure @safe nothrow+/
// 				if (is(RHS.NullableTag == NullableTag))
// 			{
// 				return this.hasValue == rhs.hasValue &&
// 					this._value == rhs._value;
// 			}
// 
// 			public bool opEquals(RHS : typeof(null))(scope RHS)
// 				const /+pure @safe nothrow+/
// 			{ return !this.hasValue; }
// 
// 			static if (!is(T == const(T)))
// 			{
// 				public auto ref opAssign(RHS)(auto ref RHS rhs)
// 					/+pure @safe nothrow+/
// 				{
// 					this._value = rhs;
// 					this._hasValue = true;
// 					return rhs;
// 				}
// 
// 				public auto ref opAssign(RHS : typeof(null))(auto ref RHS rhs)
// 					/+pure @safe nothrow+/
// 				{
// 					this._value = T.init;
// 					this._hasValue = false;
// 					return rhs;
// 				}
// 			}
// 
// 			//public alias value this;
// 		}
// 	}
// }
// 
// unittest
// {
// 	Nullable!int a = null;
// 	Nullable!int b = 5;
// 	int c = 5;
// 	assert(a != b);
// 	assert(b == c);
// 	assert(a == null);
// 	assert(b != null);
// 	assert(b + 1 == 6);
// 	struct S
// 	{
// 		public bool opEquals(S) const pure @safe nothrow
// 		{ return true; }
// 		public bool opEquals(int) const pure @safe nothrow
// 		{ return true; }
// 	}
// 	Nullable!S s;
// 	assert(s != 0);
// 	assert(s.opCmp(null) == 0);
// 	assert(a.opCmp(null) == 0);
// 	assert(b.opCmp(null) > 0);
// 	assert(b.opCmp(6) < 0);
// 	assert(b.opCmp(5) == 0);
// }
// 
// @property Nullable!(T) nullable(T)(auto ref T value) /+pure @safe 
// nothrow+/
// {
// 	Nullable!(T) result = value;
// 	return result;
// }


struct Nullable(T)
	if( isNullable!T )
{
	private T _value;

/**
Constructor binding $(D this) with $(D value).
 */
	this(A)( auto ref T value) 
		inout pure @safe nothrow
	{	_value = value; }

/**
Returns $(D true) if and only if $(D this) is in the null state.
 */
	@property bool isNull() 
		const pure @safe nothrow
	{	return _value is null;
	}
	
	/**
Forces $(D this) to the null state.
 */
	void nullify()
		pure @safe nothrow
	{	_value = null;
	}
    
	bool opEquals(RHS)(auto ref RHS rhs)
		const pure @safe nothrow
		if ( !isWebtankNullable!(RHS) )
	{	return _value == rhs; }

	bool opEquals(RHS)(auto ref RHS rhs)
		const pure @safe nothrow
		if( isWebtankNullable!(RHS) )
	{	return _value == rhs._value; }

/**
Assigns $(D value) to the internally-held state.
 */
	auto ref opAssign(ref T rhs) 
		pure @safe nothrow
	{	return _value = rhs; }

/**
Gets the value. $(D this) must not be in the null state.
This function is also called for the implicit conversion to $(D T).
 */
	@property ref inout(T) value() 
		inout pure nothrow @safe
	{	return _value;
	}

	auto ref inout(T) get()(auto ref inout(T) defaultValue) 
		inout pure nothrow @safe
	{	return isNull ? defaultValue : _value ;
	}

/**
Implicitly converts to $(D T).
$(D this) must not be in the null state.
 */
	alias value this;
}

struct Nullable(T)
	if( !isNullable!T )
{
	private T _value;
	private bool _isNull = true;

/**
Constructor initializing $(D this) with $(D value).
 */
	this( A )( auto ref inout(A) value )
		inout pure nothrow @safe
	{	_value = value;
		_isNull = false;
	}
	
	this( A : typeof(null) )( A value ) 
		inout pure @safe nothrow
	{	_isNull = true;
	}

/**
Returns $(D true) if and only if $(D this) is in the null state.
 */
	@property bool isNull() 
		const pure @safe nothrow
	{	return _isNull;
	}

/**
Forces $(D this) to the null state.
 */
	void nullify()()
		pure @safe nothrow
	{
		.destroy(_value);
		_isNull = true;
	}
	
// 	int opCmp(RHS)(scope RHS rhs)
// 		const /+pure @safe nothrow+/
// 		if (!is(RHS.NullableTag == NullableTag))
// 	{
// 		int r;
// 		if (this.hasValue)
// 		{
// 			static if (__traits(compiles, this._value.opCmp(rhs)))
// 			{ r = this._value.opCmp(rhs._value); }
// 			else
// 			{ r = this._value < rhs ? -1 : (this._value > rhs ? 1 : 0); }
// 		}
// 		else { r = -1; }
// 		return r;
// 	}
// 
// 	int opCmp(RHS)(scope RHS rhs)
// 		const /+pure @safe nothrow+/
// 		if( isWebtankNullable(RHS) )
// 	{
// 		int r;
// 		if ( !isNull && !rhs.isNull)
// 		{ r = 0; }
// 		else if( !isNull && rhs.isNull )
// 		{ r = 1; }
// 		else if ( isNull && !rhs.isNull )
// 		{ r = -1; }
// 		else { r = this == rhs._value; }
// 		return r;
// 	}
// 
// 	int opCmp(RHS : typeof(null))(scope RHS)
// 		const /+pure @safe nothrow+/
// 	{ return this.hasValue ? 1 : 0; }
	
	bool opEquals( RHS )( auto ref RHS rhs )
		const pure @safe nothrow
		if( !isWebtankNullable!(RHS) )
	{	return !isNull && _value == rhs; }

	bool opEquals( RHS )( auto ref RHS rhs )
		const pure @safe nothrow
		if( isWebtankNullable!(RHS) )
	{	return _isNull == rhs._isNull &&
			_value == rhs._value;
	}

	bool opEquals( RHS : typeof(null) )( RHS value )
		const pure @safe nothrow
	{ return isNull; }

/**
Gets the value. $(D this) must not be in the null state.
This function is also called for the implicit conversion to $(D T).
 */
	@property ref inout(T) value() 
		inout pure nothrow @safe
	{	enum message = "Attemt to get value of null " ~ typeof(this).stringof ~ "!!!";
		assert(!isNull, message);
		return _value;
	}
    
	auto ref inout(T) get()(auto ref inout(T) defaultValue) 
		inout pure nothrow @safe
	{	return ( isNull ? defaultValue : _value );
	}

/**
Assigns $(D value) to the internally-held state. If the assignment
succeeds, $(D this) becomes non-null.
 */
	auto ref opAssign( RHS )( auto ref RHS value )
		pure @safe nothrow
	{	this._value = value;
		this._isNull = false;
		return value;
	}

	auto ref opAssign( RHS : typeof(null) )( RHS value )
		pure @safe nothrow
	{	this._value = T.init;
		this._isNull = true;
		return value;
	}

/**
Implicitly converts to $(D T).
$(D this) must not be in the null state.
 */
    alias value this;
}

// void main() {
// 	
// 	import std.stdio;
// 	
// 	Nullable!int a;
// 	
// 	writeln("test");
// 	
// 	a = null;
// 	
// 	writeln(a.isNull);
// 	
// 	a = 888;
// 	auto b = a.get(666);
// 	writeln(b);
// 	
// 	writeln(a == null);
// }
