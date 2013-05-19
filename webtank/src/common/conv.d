module webtank.core.common.conv;

//Преобразование символа соотв. шестнадцатеричной цифре в байт
ubyte hexSymbolToByte(in char symbol)
{	if( symbol >= '0' && symbol <= '9' )
		return cast(ubyte) ( symbol - '0' ) ;
	else if( symbol >= 'a' && symbol <= 'f' )
		return cast(ubyte) ( symbol - 'a' + 10 );
	else if( symbol >= 'A' && symbol <= 'F' )
		return cast(ubyte) ( symbol - 'A' + 10 );
	return 0; //TODO: Подумать, что делать
}

//Функция преобразования числа из шестнадцатеричной строки в массив байтов
ubyte[] hexStringToByteArray(in string hexString)
	in {	assert( (hexString.length % 2) == 0 ); }
body
{	auto result = new ubyte[hexString.length/2];
	for( size_t i = 0; i < result.length; ++i )
	{	result[i] = cast(ubyte) ( hexSymbolToByte(hexString[2*i]) * 16 + hexSymbolToByte(hexString[2*i+1]) );
	}
	return result;
}


unittest
{	import std.digest.md;
	import std.digest.digest;
	ubyte[16] hash = md5Of("abc");
	string hexStr = std.digest.digest.toHexString(hash);
	ubyte[16] restoredHash = hexStringToByteArray(hexStr);
	assert( restoredHash == hash );
	
	string hexDigits = "0123456789ABCDEFabcdef";
	ubyte[] digits;
	foreach(s; hexDigits)
		digits ~= hexSymbolToByte(s);
	assert( [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 10, 11, 12, 13, 14, 15] == digits);
}