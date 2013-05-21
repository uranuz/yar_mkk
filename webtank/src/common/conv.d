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
	if( !low )
		throw new Exception("Количество значащих Hex-символов должно быть чётным");
	//assert( !low, "Количество значащих Hex-символов должно быть чётным" );
 	result.length = i; //Сколько раз перешли, столько реально элементов
	return result;
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

/*void main()
{	import std.stdio;
	import std.digest.digest;
	string hexStr2 = "b1e37dab-1c9a-faa5-6d03-9cb3e4399261";
	ubyte[16] hash2 = hexStringToByteArray(hexStr2);
	string restoredHexStr2 = toHexString(hash2);
	ubyte[16] hash2_1 = hexStringToByteArray(restoredHexStr2);
	writeln(hash2);
	writeln(restoredHexStr2);
	writeln( hash2_1 );
}*/

