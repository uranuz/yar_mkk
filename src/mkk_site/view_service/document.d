module mkk_site.view_service.document;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

//import std.conv, std.string, std.file, std.array;
//import mkk_site.page_devkit;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/document");
}

import ivy;
import webtank.net.http.handler;
import webtank.net.http.context;


TDataNode renderModerList(HTTPContext ctx)
{
	import std.json;
	import std.conv: to;
//*************************************************************
	JSONValue callParams;

	callParams["currentPage"] = ctx.request.bodyForm.get("currentPage", "0").to!size_t;

//**************************************************************
	auto tpl = Service.templateCache.getByModuleName("mkk.Document");

	TDataNode dataDict = mainServiceCall("document.Set", ctx, callParams);

	dataDict["isAuthenticated"] = true;


	return tpl.run(dataDict);
}

