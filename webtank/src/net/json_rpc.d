module webtank.net.json_rpc;

import std.stdio, std.string, std.conv, std.traits, std.typecons, std.json;

//Класс исключения для удалённого вызова процедур
class JSON_RPC_Exception : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

auto getDLangValue(T, uint recursionLevel = 1)(JSONValue jValue)
{	pragma(msg, T, "  ",recursionLevel);
	static if( is( T == JSONValue ) )
	{	write("JSONValue - "); writeln(jValue.type);
		return jValue; //Raw JSONValue
	}
	else static if( isBoolean!T )
	{	write("Boolean - "); writeln(jValue.type);
		if( jValue.type == JSON_TYPE.TRUE )
			return true;
		else if( jValue.type == JSON_TYPE.FALSE )
			return false;
		else
			throw new JSON_RPC_Exception("JSON value doesn't match boolean type!!!");
	}
	else static if( isIntegral!T )
	{	static if( isUnsigned!T )
		{	write("Unsigned integer - "); writeln(jValue.type);
			if( jValue.type == JSON_TYPE.UINTEGER )
				return jValue.uinteger.to!T;
			else
				throw new JSON_RPC_Exception("JSON value doesn't match unsigned integer type!!!");
		}
		else
		{	writeln("Integer - "); write(jValue.type);
			if( jValue.type == JSON_TYPE.INTEGER )
				return jValue.integer.to!T;
			else if( jValue.type == JSON_TYPE.UINTEGER  )
				return jValue.uinteger.to!T;
			else
				throw new JSON_RPC_Exception("JSON value doesn't match integer type!!!");
		}
	}
	else static if( isFloatingPoint!T )
	{	write("Floating point - "); writeln(jValue.type);
		if( jValue.type == JSON_TYPE.FLOAT )
			return jValue.floating.to!T;
		else if( jValue.type == JSON_TYPE.INTEGER )
			return jValue.integer.to!T;
		else if( jValue.type == JSON_TYPE.UINTEGER  )
			return jValue.uinteger.to!T;
		else
			throw new JSON_RPC_Exception("JSON value doesn't match floating point type!!!");
	}
	else static if( isSomeString!T )
	{	write("String - "); writeln(jValue.type);
		if( jValue.type == JSON_TYPE.STRING )
			return jValue.str.to!T;
		else
			throw new JSON_RPC_Exception("JSON value doesn't match string type!!!");
	}
	else static if( isAssociativeArray!T )
	{	write("Associative array - "); writeln(jValue.type);
		static assert( recursionLevel, "Recursion level limit!!!" );
		alias  KeyType!T AAKeyType;
		static assert( isSomeString!AAKeyType, "JSON object's key must be of string type!!!" );
		alias ValueType!T AAValueType;
		if( jValue.type == JSON_TYPE.OBJECT )
		{	T result;
			foreach( key, val; jValue.object )
				result[key.to!AAKeyType] = getDLangValue!( AAValueType, recursionLevel-1 )(val);
			return result;
		}
		else
			throw new JSON_RPC_Exception("JSON value doesn't match object type!!!");
	}
	else static if( isArray!T )
	{	write("Array - "); writeln(jValue.type);
		import std.range;
		static assert( recursionLevel, "Recursion level limit!!!" );
		alias ElementType!T AElementType;
		if( jValue.type == JSON_TYPE.ARRAY )
		{	T array;
			foreach( i, val; jValue.array )
				array[i] = getDLangValue!( AElementType, recursionLevel-1 )(val);
			return array;
		}
		else
			throw new JSON_RPC_Exception("JSON value doesn't match array type!!!");
	}
	else static if( isTuple!T )
	{	write("Tuple - "); writeln(jValue.type);
		T result;
		if( jValue.type == JSON_TYPE.ARRAY )
		{	if( jValue.array.length != T.length )
				throw new JSON_RPC_Exception("JSON array length " ~ T.length.to!string ~ " expected but " ~ jValue.array.length.to!string ~ " found!!!");
			foreach( i, ref element; result )
				element = getDLangValue!( typeof(element), recursionLevel-1 )(jValue.array[i]);
		}
		else if( jValue.type != JSON_TYPE.OBJECT )
		{	if( jValue.object.length != T.length )
				throw new JSON_RPC_Exception("JSON array length " ~ T.length.to!string ~ " expected but " ~ jValue.object.length.to!string ~ " found!!!");
			static if( T.length != 0 )
				result[0] = getDLangValue!( T.Types[0], recursionLevel-1 )(jValue);
		}
		else
			throw new JSON_RPC_Exception("JSON value doesn't match tuple type!!!");
		writeln(result);
		return result;
	}
	else
		static assert( 0, "This should never happen!!!" );
	//TODO: Добавить работу с Tuple
}

JSONValue getJSONValue(T)(T dValue)
{	static if( is( T == JSONValue ) )
		return dValue;
	else
	{	JSONValue jValue;
		static if( isBoolean!T )
		{	jValue.type = ( dValue ? JSON_TYPE.TRUE : JSON_TYPE.FALSE );
		}
		else static if( isIntegral!T )
		{	static if( isSigned!T )
			{	jValue.type = JSON_TYPE.INTEGER;
				jValue.integer = dValue.to!long;
			}
			else static if( isUnsigned!T )
			{	jValue.type = JSON_TYPE.UINTEGER;
				jValue.uinteger = dValue.to!ulong;
			}
			else
				static assert( 0, "This should never happen!!!" ); //Это не должно произойти))
		}
		else static if( isFloatingPoint!T )
		{	jValue.type = JSON_TYPE.FLOAT;
			jValue.floating = dValue.to!real;
		}
		else static if( isSomeString!T )
		{	jValue.type = ( dValue is null ? JSON_TYPE.NULL : JSON_TYPE.STRING );
			jValue.str = dValue.to!string;
		}
		else static if( isArray!T )
		{	jValue.type = ( dValue is null ? JSON_TYPE.NULL : JSON_TYPE.ARRAY );
			foreach( elem; dValue )
				jValue.array ~= getJSONValue( elem );
		}
		else static if( isAssociativeArray!T )
		{	jValue.type = ( dValue is null ? JSON_TYPE.NULL : JSON_TYPE.OBJECT );
			foreach( key, val; dValue )
				jValue.object[key] = getJSONValue( val );
		}
		else static if( isTuple!T )
		{	jValue.type = JSON_TYPE.ARRAY;
			foreach( elem; dValue )
				jValue.array ~= getJSONValue( elem );
		}
		else
			static assert( 0, "This value's type is not of one implemented JSON type!!!" );
		return jValue;
	}
}

// void main()
// {	
// 	auto vasya = Tuple!(double, "хрень", bool, "ыыы", string, "чо")(16, true, "ололо");
// 	auto jValue = getJSONValue(vasya);
// 	writeln(toJSON(&jValue));
// }