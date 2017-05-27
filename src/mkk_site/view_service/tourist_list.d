module mkk_site.view_service.tourist_list;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderTouristList)("/dyn/tourist/list");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderTouristList(HTTPContext ctx)
{
	debug import std.stdio: writeln;

	debug writeln(`tourist request headers: `, ctx.request.headers.toAA());
	import std.json;
	import std.conv: to;
//*************************************************************
	JSONValue callParams;
	
	callParams["curPageNum"] = ctx.request.bodyForm.get("cur_page_num", "1").to!size_t;
	callParams["familyName"] = ctx.request.bodyForm.get("family_name", null);
	callParams["givenName"]  = ctx.request.bodyForm.get("given_name", null);
	callParams["patronymic"] = ctx.request.bodyForm.get("patronymic", null);
//**************************************************************
	
	auto tpl = Service.templateCache.getByModuleName("mkk.TouristList");
	//TDataNode dataDict;
	//dataDict["tourist_list"] = mainServiceCall("tourist.Set", ctx, callParams);
	
	TDataNode dataDict = mainServiceCall("tourist.Set", ctx, callParams);
	//dataDict["familyName"] =  ctx.request.bodyForm.get("family_name", null);

	return tpl.run(dataDict).str;
}

