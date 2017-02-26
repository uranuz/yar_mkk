module mkk_site.view_service.index;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/index");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

TDataNode readRecentPohodList()
{
	import std.json;
	JSONValue emptyJSON;
	return sendJSON_RPCRequestAndWaitAsIvyNode( "http://localhost/jsonrpc/", "pohod.recentList", emptyJSON );
}


string renderIndex(HTTPContext ctx)
{
	auto tpl = Service.templateCache.getByModuleName("mkk.index");
	TDataNode dataDict;
	dataDict["pohod_list"] = readRecentPohodList();

	return tpl.run(dataDict).str;
}