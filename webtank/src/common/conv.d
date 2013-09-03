module webtank.common.conv;

//Преобразование символа соотв. шестнадцатеричной цифре в байт
ubyte hexSymbolToByte(char symbol)
{	if( symbol >= '0' && symbol <= '9' )
		return cast(ubyte) ( symbol - '0' ) ;
	else if( symbol >= 'a' && symbol <= 'f' )
		return cast(ubyte) ( symbol - 'a' + 10 );
	else if( symbol >= 'A' && symbol <= 'F' )
		return cast(ubyte) ( symbol - 'A' + 10 );
	return 0; //TODO: Подумать, что делать
}

bool isHexSymbol(char symbol)
{	return 
		( symbol >= '0' && symbol <= '9' ) || ( symbol >= 'a' && symbol <= 'f' ) || ( symbol >= 'A' && symbol <= 'F' );
}

//Функция преобразования числа из шестнадцатеричной строки в массив байтов
ubyte[] hexStringToByteArray(string hexString)
{	auto result = new ubyte[hexString.length/2]; //Выделяем с запасом (в строке могут быть "лишние" символы)
	size_t i = 0; //Индексация результирующего массива
	bool low = false;
	foreach( symbol; hexString )
	{	if( isHexSymbol(symbol) )
		{	if( low )
			{	result[i] += cast(ubyte) hexSymbolToByte(symbol);
				i++; //После добавления младшего символа переходим к след. элементу
			}
			else
				 result[i] = cast(ubyte) ( hexSymbolToByte(symbol) * 16 );
			low = !low; 
		}
	}
	if( low )
		throw new Exception("Количество значащих Hex-символов должно быть чётным");
	//assert( !low, "Количество значащих Hex-символов должно быть чётным" );
 	result.length = i; //Сколько раз перешли, столько реально элементов
	return result;
}

ubyte[arrayLen] hexStringToStaticByteArray(size_t arrayLen)(string hexString)
{	ubyte[arrayLen] result;
	size_t i = 0; //Индексация результирующего массива
	bool low = false;
	foreach( symbol; hexString )
	{	if( isHexSymbol(symbol) )
		{	if( i >= arrayLen )
				new Exception( "Количество значащих символов слишком велико для соответствия размеру результата" );
			if( low )
			{	result[i] += cast(ubyte) hexSymbolToByte(symbol);
				i++; //После добавления младшего символа переходим к след. элементу
			}
			else
				 result[i] = cast(ubyte) ( hexSymbolToByte(symbol) * 16 );
			low = !low; 
		}
	}
	if( low )
		throw new Exception("Количество значащих Hex-символов должно быть чётным");
	return result;
}

string toHexString(uint arrayLen)(ubyte[arrayLen] srcArray)
{	import std.digest.digest;
	return std.digest.digest.toHexString(srcArray).idup;
}

//Набор тестов для функций преобразования
unittest
{	import std.digest.md;
	import std.digest.digest;
	ubyte[16] hash = md5Of("abc");
	string hexStr = std.digest.digest.toHexString(hash);
	ubyte[16] restoredHash = hexStringToByteArray(hexStr);
	assert( restoredHash == hash );
	
	string hexStr2 = "b1e37dab-1c9a-faa5-6d03-9cb3e4399261";
	ubyte[16] hash2 = hexStringToByteArray(hexStr2);
	string restoredHexStr2 = toHexString(hash2);
	ubyte[16] hash2_1 = hexStringToByteArray(restoredHexStr2);
	assert( hash2_1 == hash2 );
	
	string hexDigits = "0123456789ABCDEFabcdef";
	ubyte[] digits;
	foreach(s; hexDigits)
		digits ~= hexSymbolToByte(s);
	assert( [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 10, 11, 12, 13, 14, 15] == digits);
}

/**
Списочек важных, наиболее используемых типов:


*/

// template convDef(R)
// {	import std.conv;
// 	import std.string;
// 	R convDef(string src, R defaultValue = R.init)
// 	{	try
// 		{	static if( is( R: bool ) )
// 			{	
// 				
// 				foreach( val; _logicTrueValues  )
// 					if( toLower( strip(src) ) == val ) 
// 						return true;
// 				foreach( val; _logicFalseValues  )
// 					if( toLower( strip(src) ) == val ) 
// 						return false;
// 				return defaultValue;
// 			}
// 			else
// 			{	return std.conv.to!R(src);
// 			}
// 		}
// 		catch(std.conv.ConvException e)
// 		{	return defaultValue;
// 		}
// 	}
// }


enum trueStrings = 
[`true`, `t`, `yes`, `y`, `истина`, `и`, `да`, `д`, `on`, `1`];
enum falseStrings = 
[`false`, `f`, `no`, `n`, `ложь`, `л`, `нет`, `н`, `off`, `0`];

//Функция пытается преобразовать исходное значение src в заданный тип и обратно
//в случае неудачи возвращается defaultValue
template verify(T, R)
{	import std.conv;
	R verify(R src, R defaultValue = R.init)
	{	try
		{	static if( is( R: string ) )
			{	import std.string;
				static if( is( T: bool ) )
				{	foreach( logicStr; trueStrings )
						if( toLower( strip(src) ) == logicStr )
							return "да";
					foreach( logicStr; falseStrings )
						if( toLower( strip(src) ) == logicStr )
							return "нет";
					return defaultValue;
				}
				else static if( __traits(isScalar, T) )
				{	auto convFvdValue = std.conv.to!T(src);
					return std.conv!R(convFvdValue);
				}
				else
					static assert(0, "Not implemented!");
			}
			else
				static assert(0, "Not implemented!");
		}
		catch(std.conv.ConvException e)
		{	return defaultValue;
		}
		
	}
	
}


// void main()
// {	import std.stdio;
// 	import std.digest.digest;
// 	string hexStr2 = "b1e37dab-1c9a-faa5-6d03-9cb3e4399261";
// 	ubyte[16] hash2 = hexStringToByteArray(hexStr2);
// 	string restoredHexStr2 = toHexString(hash2);
// 	ubyte[16] hash2_1 = hexStringToByteArray(restoredHexStr2);
// 	writeln(hash2);
// 	writeln(restoredHexStr2);
// 	writeln( hash2_1 );
// 	writeln( convDef!bool(" p ", true) );
// 	
// }
