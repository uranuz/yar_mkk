module webtank.net.json_rpc;

// import webtank._version;

import webtank.common.serialization;

import std.stdio, std.string, std.conv, std.traits, std.typecons, std.json;

//Класс исключения для удалённого вызова процедур
class JSON_RPC_Exception : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

template callJSON_RPC_Method(alias Method)
{	
	import std.traits, std.json, std.conv, std.typecons;
	alias ParameterTypeTuple!(Method) ParamTypes;
	alias ReturnType!(Method) ResultType;
	alias ParameterIdentifierTuple!(Method) ParamNames;
	
	JSONValue callJSON_RPC_Method(JSONValue jValue)
	{	JSONValue result;
		result.type = JSON_TYPE.NULL;  //По-умолчанию в качестве результата null
		
		static if( ParamTypes.length == 0 )
		{	
			if( jValue.type == JSON_TYPE.NULL   )
			{	//Don't remove!!!
			}
			else if( jValue.type == JSON_TYPE.OBJECT )
			{	if( jValue.object.length != 0 )
					throw new JSON_RPC_Exception(
						"Calling method without params. But got JSON object with " 
						~ jValue.object.length.to!string ~ " parameters "
					);
			}
			else
				throw new JSON_RPC_Exception( 
					"Unsupported JSON value type!!!"
				);
			
			static if( is( ResultType == void ) )
				Method(); //Вызов метода без параметров и возвращаемого значения
			else
				result = getStdJSON( Method() ); //Вызов метода без параметров с возвращаемым значением
		}
		else
		{	
			if( jValue.type == JSON_TYPE.OBJECT )
			{	
				writeln("jValue.object.length: ", jValue.object.length);
				if( ParamTypes.length == jValue.object.length )
				{	
// 					pragma(msg, ParamTypes);
					Tuple!(ParamTypes) argTuple;
// 					pragma(msg, typeof(argTuple));
					foreach( i, type; ParamTypes )
					{	pragma(msg, "Current type is ", type, " ", i);
						if( ParamNames[i] in jValue.object )
						{	
							auto dValue = getDLangValue!(type)( jValue.object[ ParamNames[i] ] );
							pragma(msg, "Typeof dValue is ", typeof(dValue));
							argTuple[i] = dValue;
						}
						else
							throw new JSON_RPC_Exception( 
								"Expected JSON-RPC parameter " ~ ParamNames[i]
								~ " is not found in param object!!!"
							);
					}
					
					static if( is( ResultType == void ) )
						Method(argTuple.expand);
					else
						result = getStdJSON( Method(argTuple.expand) );
				}
				else
					throw new JSON_RPC_Exception( 
						"Expected JSON-RPC params count is " ~ ParamTypes.length.to!string
						~ " but got " ~ jValue.object.length.to!string
					);
			}
			else
				throw new JSON_RPC_Exception( 
					"Unsupported JSON value type!!!"
				);
		}
		
		return result;
	}
}