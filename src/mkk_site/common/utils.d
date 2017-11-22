module mkk_site.common.utils;

string buildNormalPath(T...)(T args)
{
	import std.path: buildNormalizedPath;
	import std.algorithm: endsWith;

	string result = buildNormalizedPath(args);

	static if( args.length > 0 )
	{
		//Возвращаем на место слэш в конце пути, который выкидывает стандартная библиотека
		if( result.length > 1 && args[$-1].endsWith("/") && !result.endsWith("/") )
			result ~= '/';
	}

	return result;
}

string[] parseExtraFileLink(string linkPair)
{	import std.algorithm : splitter;
	import std.algorithm : startsWith;
	auto linkPairSplitter = splitter(linkPair, "><");
	string link = linkPairSplitter.empty ? null : linkPairSplitter.front;
	string comment;

	if( link.length > 0 && link.length+2 < linkPair.length )
		comment = linkPair[ link.length+2..$ ];
	else
	{	if( !linkPair.startsWith("><") )
			link = linkPair;
	}

	return [ link, comment ];
}