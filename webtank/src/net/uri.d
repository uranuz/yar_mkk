module webtank.net.uri;

import std.string;
import std.exception;
import std.uri;
import std.utf;

//Эта функция принимает строку похожую на URI-запрос и анализирует. Результат 
//возращается в ассоциативный массив типа  значение[ключ]. Осторожно, функция 
//кидается исключениями, если что-то не так. Если запрос пуст, то возвращается
//массив с одной парой с пустым ключом и значением (чтобы при переборе оператором
//foreach не вылетало с исключением)
string[string] parseURIQuery(string queryStr) 
{
	string[string] Res;
	if (queryStr=="") { Res[""]=""; return Res; }
		
	string ProcStr=queryStr;
	string Key=""; int i=0; bool KeyStarted=true; bool ValueStarted=false;
	
	while (true)
	{	
		if ( i>=ProcStr.length ) 
		{	if (  ( (queryStr[$-1]=='=') 
				|| Res.length==0) && (Key=="")  ) 
				throw new Exception("Не найден ключ в конце строки");
			else if (queryStr[$-1]=='&') throw new Exception("'&' не разрешён в конце строки");
			else Res[Key]=ProcStr[0..$];
			break;
		}
		if ( (ProcStr[i]=='=') || (ProcStr[i]=='&') )
		{	string Lex=ProcStr[0..i];
			if (ProcStr[i]=='=') 
			{	if (ValueStarted==true) throw new Exception("Не найден разделитель переменных в выражении '"~Lex~"'");
				else
				{	Key=Lex;
					KeyStarted=true; ValueStarted=true;
				} 
			}
			else if (ProcStr[i]=='&') 
			{	if (KeyStarted==true && (Key!="") )
				{	Res[Key]=Lex; KeyStarted=false; Key=""; ValueStarted=false;
				}
				else throw new Exception("Не найден ключ в выражении '"~Lex~"'");
			}
			ProcStr=ProcStr[i+1..$]; i=0;
			continue;
		}
		++i;
	}
	return Res;
}

dstring[dstring] parseURIQuery2(dstring queryStr)
{	dstring[dstring] result;
	size_t LexStart = 0;
	dstring curKey;
	dstring curValue;
	for( size_t i = 0; i < queryStr.length; ++i )
	{	if( queryStr[i] == '=' )
		{	curKey = queryStr[LexStart..i].idup;
			curValue = null;
			LexStart = i+1;
		}
		if( (queryStr[i] == '&') || (i+1 == queryStr.length) )
		{	curValue = queryStr[ LexStart .. (i+1 == queryStr.length) ? ++i : i ].idup;
			if( curKey.length > 0)
			{	result[curKey] = curValue; }
			curKey = null;
			LexStart = i+1;
		}
	}
	return result;
}

string[string] parseURIQuery2(string queryStr)
{	string[string] result;
	import std.utf;
	foreach( key, value; parseURIQuery2( toUTF32(queryStr) ) )
		result[ toUTF8(key) ] = toUTF8(value);
	return result;
}


unittest
{	string Query="ff=adfggg&text_inp1=kirpich&text_inp2=another_text&opinion=kupi_konya";
	string[string] Res=parseURIQuery(Query);
	assert(Res.length==4);
	assert (  Res["ff"]=="adfggg" && Res["text_inp1"]=="kirpich" && 
	          Res["text_inp2"]=="another_text" && Res["opinion"]=="kupi_konya"  );
	
}

string[string] extractURIData(string queryStr)
{	string[string] result;
	foreach( key, value; parseURIQuery2( queryStr ) )
		result[ decodeURI(key) ] = decodeURI(value);
	return result;
}

//Декодировать URI. Прослойка на случай, если захотим написать свою версию, отличную
//от стандартной. TODO: Может переписать через alias? (однако неудобно смотреть аргументы)
string decodeURI(string src) 
{	char[] result = src.dup;
	for ( int i = 0; i < src.length; ++i )
	{	if ( src[i] == '+' ) result[i] = ' '; //Заменяем плюсики на пробелы
	}
	return decodeComponent(result.idup);
}
