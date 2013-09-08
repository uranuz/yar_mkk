module webtank.net.json_rpc;

import std.stdio, std.string, std.conv, std.traits, std.typecons, std.json;

//Класс исключения для удалённого вызова процедур
class JSON_RPC_Exception : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

auto getJSONValue(T, uint recursionLevel = 1)(JSONValue jvalue)
{	pragma(msg, T, "  ",recursionLevel);
	static if( is( T == JSONValue ) )
		return jvalue; //Raw JSONValue
	else static if( isBoolean!T )
	{	if( jvalue.type == JSON_TYPE.TRUE )
			return true;
		else if( jvalue.type == JSON_TYPE.FALSE )
			return false;
		else
			throw new JSON_RPC_Exception("JSON value doesn't match boolean type!!!");
	}
	else static if( isIntegral!T )
	{	static if( isUnsigned!T )
		{	if( jvalue.type == JSON_TYPE.UINTEGER )
				return jvalue.uinteger.to!T;
			else
				throw new JSON_RPC_Exception("JSON value doesn't match unsigned integer type!!!");
		}
		else
		{	if( jvalue.type == JSON_TYPE.INTEGER )
				return jvalue.integer.to!T;
			else if( jvalue.type == JSON_TYPE.UINTEGER  )
				return jvalue.uinteger.to!T;
			else
				throw new JSON_RPC_Exception("JSON value doesn't match integer type!!!");
		}
	}
	else static if( isFloatingPoint!T )
	{	if( jvalue.type == JSON_TYPE.FLOAT )
			return jvalue.floating.to!T;
		else if( jvalue.type == JSON_TYPE.INTEGER )
			return jvalue.integer.to!T;
		else if( jvalue.type == JSON_TYPE.UINTEGER  )
			return jvalue.uinteger.to!T;
		else
			throw new JSON_RPC_Exception("JSON value doesn't match floating point type!!!");
	}
	else static if( isSomeString!T )
	{	if( jvalue.type == JSON_TYPE.STRING )
			return jvalue.str.to!T;
		else
			throw new JSON_RPC_Exception("JSON value doesn't match string type!!!");
	}
	else static if( isAssociativeArray!T )
	{	static assert( recursionLevel, "Recursion level limit!!!" );
		alias  KeyType!T AAKeyType;
		static assert( isSomeString!AAKeyType, "JSON object's key must be of string type!!!" );
		alias ValueType!T AAValueType;
		if( jvalue.type == JSON_TYPE.OBJECT )
		{	T result;
			foreach( key, val; jvalue.object )
			{	result[key.to!AAKeyType] = getJSONValue!( AAValueType, recursionLevel-1 )(val);
			}
			return result;
		}
		else
			throw new JSON_RPC_Exception("JSON value doesn't match object type!!!");
	}
	else static if( isArray!T )
	{	import std.range;
		static assert( recursionLevel, "Recursion level limit!!!" );
		alias ElementType!T AElementType;
		if( jvalue.type == JSON_TYPE.ARRAY )
		{	T array;
			foreach( i, val; jvalue.array )
			{	array[i] = getJSONValue!( AElementType, recursionLevel-1 )(val);
			}
			return array;
		}
		else
			throw new JSON_RPC_Exception("JSON value doesn't match array type!!!");
	}
	else static if( isTuple!T )
	{	T result;
		if( jvalue.type == JSON_TYPE.ARRAY )
		{	if( jvalue.array.length != T.length )
				throw new JSON_RPC_Exception("JSON array length " ~ T.length.to!string ~ " expected but " ~ jvalue.array.length.to!string ~ " found!!!");
			foreach( i, ref element; result )
				element = getJSONValue!( typeof(element), recursionLevel-1 )(jvalue.array[i]);
		}
		else if( jvalue.type != JSON_TYPE.OBJECT )
		{	result[0] = getJSONValue!( T.Types[0], recursionLevel-1 )(jvalue);
		}
		else
			throw new JSON_RPC_Exception("JSON value doesn't match tuple type!!!");
		return result;
	}
	else
		static assert( 0, "This should never happen!!!" );
	//TODO: Добавить работу с Tuple
}

