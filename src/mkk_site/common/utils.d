module mkk_site.common.utils;

string[] parseExtraFileLink(string linkPair)
{
	import std.algorithm : splitter;
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

import webtank.net.http.context: HTTPContext;
import mkk_site.common.versions: isMKKSiteDevelTarget;

string getAuthRedirectURI(HTTPContext context)
{
	string query = context.request.uri.query;
	//Задаем ссылку на аутентификацию
	static if( isMKKSiteDevelTarget )
		return
			"/dyn/auth?redirectTo=" ~ context.request.uri.path	~ "?" ~ query;
	else
		return
			"https://" ~ context.request.headers.get("x-forwarded-host", "")
			~ "/dyn/auth?redirectTo="
			~ context.request.headers.get("x-forwarded-proto", "http") ~ "://"
			~ context.request.headers.get("x-forwarded-host", "")
			~ context.request.uri.path ~ ( query.length ? "?" ~ query : "" );
}