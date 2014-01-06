module webtank.common.nullable;

import std.stdio;





// 
// 
// 
private struct NullableTag { }
template isNullable(T) { enum isNullable = __traits(compiles, 
T.init == null); }

template Nullable(T)
{
	static if (isNullable!(T)) { alias T Nullable; }
	else
	{
		struct Nullable
		{
			// To tell if something is Nullable
			private alias .NullableTag NullableTag;
			private T _value;
			private bool _hasValue;

			public this(A)(auto ref A value)
				inout /+pure @safe nothrow+/
			{
				this._value = value;
				this._hasValue = true;
			}

			public this(A : typeof(null))(A)
				inout /+pure @safe nothrow+/ { }

			public @property ref const(bool) hasValue()
				const /+pure @safe nothrow+/
			{ return this._hasValue; }

			public @property ref inout(T) value()
				inout /+pure @safe+/
			{ return *(this._hasValue ? &this._value : null); }

			public int opCmp(RHS)(scope RHS rhs)
				const /+pure @safe nothrow+/
				if (!is(RHS.NullableTag == NullableTag))
			{
				int r;
				if (this.hasValue)
				{
					static if (__traits(compiles, this._value.opCmp(rhs)))
					{ r = this._value.opCmp(rhs._value); }
					else
					{ r = this._value < rhs ? -1 : (this._value > rhs ? 1 : 0); }
				}
				else { r = -1; }
				return r;
			}

			public int opCmp(RHS)(scope RHS rhs)
				const /+pure @safe nothrow+/
				if (is(RHS.NullableTag == NullableTag))
			{
				int r;
				if (this.hasValue && rhs.hasValue)
				{ r = 0; }
				else if (this.hasValue && !rhs.hasValue)
				{ r = 1; }
				else if (!this.hasValue && rhs.hasValue)
				{ r = -1; }
				else { r = this == rhs._value; }
				return r;
			}

			public int opCmp(RHS : typeof(null))(scope RHS)
				const /+pure @safe nothrow+/
			{ return this.hasValue ? 1 : 0; }

			public bool opEquals(RHS)(scope RHS rhs)
				const /+pure @safe nothrow+/
				if (!is(RHS.NullableTag == NullableTag))
			{ return this.hasValue && this._value == rhs; }

			public bool opEquals(RHS)(scope RHS rhs)
				const /+pure @safe nothrow+/
				if (is(RHS.NullableTag == NullableTag))
			{
				return this.hasValue == rhs.hasValue &&
					this._value == rhs._value;
			}

			public bool opEquals(RHS : typeof(null))(scope RHS)
				const /+pure @safe nothrow+/
			{ return !this.hasValue; }

			static if (!is(T == const(T)))
			{
				public auto ref opAssign(RHS)(auto ref RHS rhs)
					/+pure @safe nothrow+/
				{
					this._value = rhs;
					this._hasValue = true;
					return rhs;
				}

				public auto ref opAssign(RHS : typeof(null))(auto ref RHS rhs)
					/+pure @safe nothrow+/
				{
					this._value = T.init;
					this._hasValue = false;
					return rhs;
				}
			}

			//public alias value this;
		}
	}
}

unittest
{
	Nullable!int a = null;
	Nullable!int b = 5;
	int c = 5;
	assert(a != b);
	assert(b == c);
	assert(a == null);
	assert(b != null);
	assert(b + 1 == 6);
	struct S
	{
		public bool opEquals(S) const pure @safe nothrow
		{ return true; }
		public bool opEquals(int) const pure @safe nothrow
		{ return true; }
	}
	Nullable!S s;
	assert(s != 0);
	assert(s.opCmp(null) == 0);
	assert(a.opCmp(null) == 0);
	assert(b.opCmp(null) > 0);
	assert(b.opCmp(6) < 0);
	assert(b.opCmp(5) == 0);
}

@property Nullable!(T) nullable(T)(auto ref T value) /+pure @safe 
nothrow+/
{
	Nullable!(T) result = value;
	return result;
}


struct Nullable(T)
	if( is( T == class ) || isSomeFunction!(T) )
{
    private T _value;

/**
Constructor binding $(D this) with $(D value).
 */
    this(T value) pure nothrow @safe
    {
        _value = value;
    }

/**
Returns $(D true) if and only if $(D this) is in the null state.
 */
    @property bool isNull() const pure nothrow @safe
    {
        return _value is null;
    }

/**
Forces $(D this) to the null state.
 */
    void nullify() pure nothrow @safe
    {
        _value = null;
    }

/**
Assigns $(D value) to the internally-held state.
 */
    void opAssign()(T value)
        if (isAssignable!T) //@@@9416@@@
    {
//         enum message = "Called `opAssign' on null NullableRef!" ~ T.stringof ~ ".";
//         assert(!isNull, message);
        *_value = value;
    }

/**
Gets the value. $(D this) must not be in the null state.
This function is also called for the implicit conversion to $(D T).
 */
    @property ref inout(T) get() inout pure nothrow @safe
    {
        enum message = "Called `get' on null NullableRef!" ~ T.stringof ~ ".";
        assert(!isNull, message);
        return *_value;
    }

/**
Implicitly converts to $(D T).
$(D this) must not be in the null state.
 */
    alias get this;
}

struct Nullable(T)
	if( is( T : struct ) )
{
    private T _value;
    private bool _isNull = true;

/**
Constructor initializing $(D this) with $(D value).
 */
    this(inout T value) inout
    {
        _value = value;
        _isNull = false;
    }

/**
Returns $(D true) if and only if $(D this) is in the null state.
 */
    @property bool isNull() const pure nothrow @safe
    {
        return _isNull;
    }

/**
Forces $(D this) to the null state.
 */
    void nullify()()
    {
        .destroy(_value);
        _isNull = true;
    }

/**
Assigns $(D value) to the internally-held state. If the assignment
succeeds, $(D this) becomes non-null.
 */
    void opAssign()(T value)
    {		writeln("Nullable.opAssign called");
        _value = value;
        _isNull = false;
    }

/**
Gets the value. $(D this) must not be in the null state.
This function is also called for the implicit conversion to $(D T).
 */
    @property ref inout(T) get() inout /+pure nothrow @safe+/
    {		writeln("Nullable.get called");
        enum message = "Called `get' on null Nullable!" ~ T.stringof ~ ".";
        assert(!isNull, message);
        return _value;
    }

/**
Implicitly converts to $(D T).
$(D this) must not be in the null state.
 */
    alias get this;
}

void main() {
	
	import std.stdio;
	
	Nullable!int a;
	
	a = 100500;
	
	writeln(a);
}