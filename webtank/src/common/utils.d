module webtank.common.utils;

///Функции разделения массивов по разделителю delim
E[][] splitArray(E, D)(E[] array, D delim)
	if( !is( D : E[] ) )
{	import std.conv;
	return splitArray( array, std.conv.to!(E[])(delim) );
}

E[][] splitArray(E)(E[] array, E[] delim)
{	E[][] result;
	size_t startPos = 0;
	foreach( i, e; array)
	{	if( i + delim.length <= array.length )
		{	if( array[i..i+delim.length] == delim  )
			{	result ~= array[startPos..i];
				startPos = i+delim.length;
			}
		}
		else
			break;
	}
	result ~= array[startPos..$];
	return result;
}

///Возвращют первый элемент при разделении массива по delim
E[] splitFirst(E, D)(E[] array, D delim)
	if( !is( D : E[] ) )
{	import std.conv;
	return splitFirst( array, std.conv.to!(E[])(delim) );
}

E[] splitFirst(E)(E[] array, E[] delim)
{	E[] result;
	foreach( i, e; array )
	{	if( i + delim.length <= array.length )
		{	if( array[i..i+delim.length] == delim  )
				return array[0..i];
		}
		else
			return null;
	}
	return null;
}


///Возвращют последний элемент при разделении массива по delim
E[] splitLast(E, D)(E[] array, D delim)
	if( !is( D : E[] ) )
{	import std.conv;
	return splitLast( array, std.conv.to!(E[])(delim) );
}

E[] splitLast(E)(E[] array, E[] delim)
{	E[] result;
	foreach_reverse( i, e; array )
	{	if( i-delim.length >= 0 )
		{	if( array[i-delim.length+1 .. i+1] == delim  )
				return array[i+1..$];
		}
		else
			return null;
	}
	return null;
}

