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

import std.traits;

///Метод рекурсивно создаёт изменяемую копию ассоциативного массива
///Рекурсия проходит только по значениям ассоц. массива
auto mutCopy(K, V)(const(V[K]) array)
{
	alias Unqual!(V) MV;
	alias Unqual!(K) MK;

	MV[MK] result;
		
	foreach( key, val; array )
	{	static if( isScalarType!(MV) )
			result[key] = val;
		else
			result[key] = val.mutCopy();
	}
	return result;
}

///Метод рекурсивно создаёт копию обычного массива из константного
auto mutCopy(V)(const(V[]) array)
{
	alias Unqual!(V) MV;
		
	MV[] result;
	foreach( val; array )
	{	static if( isScalarType!(MV) )
			result ~= val;
		else
			result ~= val.mutCopy();
	}
	return result;
	
}

unittest
{
	struct EnumFormat
	{
		this(immutable(string[int]) names) immutable
		{	_names = names;
			
		}
		
		this( const(EnumFormat) format ) 
		{	foreach( key, val; format._names )
				_names[key] = val;
		}
		
		EnumFormat mutCopy() const
		{	EnumFormat fmt = EnumFormat(this);
			return fmt;
		}
		
		
	protected:
		string[int] _names;	
	}
	
	immutable(EnumFormat) categories;
	immutable(EnumFormat) magicCreatures;
	immutable(EnumFormat) daysOfWeek;
	
	categories = immutable(EnumFormat)([ 1: "first", 2: "second", 3: "third", 6: "highest"  ]);
	magicCreatures = immutable(EnumFormat)([ 2: "ork", 3: "goblin", 4: "elf", 7: "dwarf", 10: "dragon" ]);
	daysOfWeek = immutable(EnumFormat)([ 0: "sunday", 1: "monday", 2: "tuesday", 3: "wednesday" ]);
	
	immutable(int)[string] a1;
 	immutable(int[string]) a2;
 	int[immutable(double)] a3;
 	immutable(int)[double] a4;
 	immutable(int)[immutable(double)] a5;
 	immutable(EnumFormat)[string] a6;
 	immutable(EnumFormat[string]) a7;
 	immutable(EnumFormat[immutable(double)]) a8;
 	immutable(int)[char[]] a1;
 	
 	//static assert( is( typeof(a1) == int[string] ) );
	//static assert( is( typeof(a2) == int[string] ) );
}

import std.traits;

///Попытка реализации событий
///В текущей реализации обработчик должен возвращать bool или ничего (void)
///Возврат обработчиком значения true или возникновение исключения вызывает
///прерывание цепочки обработчиков
class Event(T)
	if( isCallable!(T) && ( is( ReturnType!(T) == void ) || is( ReturnType!(T) == bool ) ) )
{
	this() const {}
	
	private T[] _handlers;
	
	///Добавление обработчика события
	void opOpAssign(string op)( T handler ) if( op == "~" )
	{	_handlers ~= handler; }
	
	///Запуск всех обработчиков
	bool fire(TL...)(TL params) const
	{	foreach( hdl; _handlers)
		{	static if( is( ReturnType!(T) == void ) )
			{	hdl(params);
			}
			else static if( is( ReturnType!(T) == bool ) )
			{	if( hdl(params) )
					return true;
			}
		}
		
		return false;
	}
	
	import std.algorithm;
	
	void remove( T handler )
	{	auto index = countUntil(_handlers, handler);
		if( index != -1 )
		{	_handlers = ( index ==_handlers.length-1 ? _handlers[0..$-1] : _handlers[0..index] ~ _handlers[index+1..$] );
		}
	}
	
}
