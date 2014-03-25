module webtank.net.web_form;

import std.range;

import webtank.net.uri;

template parseFormData(bool isMulti = false)
{
	auto parseFormData(T)(T input)
	{
		import std.algorithm: canFind;

		if( input.empty )
			return null;

		static if( isMulti )
			T[][T] result;
		else
			T[T] result;

		T curKey = input.save();
		T curValue = input.save();
		size_t count = 0;


		for( input = input[]; !input.empty; input.popFront(), count++ )
		{
			auto c = input.front;
			if( !(
				'a' <= c && c <= 'z' ||
				'A' <= c && c <= 'Z' ||
				'0' <= c && c <= '9' ||
				"-._~!$&'()*+,;=/?".canFind(c)
				)
			)	throw new Exception("Invalid urlencoded form data!!!");

			if( c == '=' )
			{
				curKey = curKey[0..count];
				count = 0;

				input.popFront();
				curValue = input.save();
			}
			else if( c == '&' )
			{
				static if( isMulti )
					result[curKey] ~= curValue[0..count];
				else
					result[curKey] = curValue[0..count];
				
				count = 0;
				curKey = null;
				curValue = null;

				input.popFront();
				curKey = input.save();
			}
		}

		if( !curValue.empty )
		{
			static if( isMulti )
				result[curKey] ~= curValue[0..count];
			else
				result[curKey] = curValue[0..count];
		}

		return result;
	}
}

alias parseFormData!(true) parseFormDataMulti;

unittest
{	string Query="ff=adfggg&text_inp1=kirpich&text_inp2=another_text&opinion=kupi_konya";
	string[string] Res=parseFormData(Query);
	assert(Res.length==4);
	assert (  Res["ff"]=="adfggg" && Res["text_inp1"]=="kirpich" &&
	          Res["text_inp2"]=="another_text" && Res["opinion"]=="kupi_konya"  );

}

string[string] extractFormData(string queryStr)
{	string[string] result;
	foreach( key, value; parseFormData( queryStr ) )
		result[ decodeURIFormQuery(key) ] = decodeURIFormQuery(value);
	return result;
}

string[][string] extractFormDataMulti(string queryStr)
{	string[][string] result;
	foreach( key, values; parseFormDataMulti( queryStr ) )
	{	string decodedKey = decodeURIFormQuery(key);
		foreach( val; values )
			result[ decodedKey ] ~= decodeURIFormQuery(val);
	}
	return result;
}