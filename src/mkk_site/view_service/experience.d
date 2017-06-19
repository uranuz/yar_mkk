module mkk_site.view_service.experience;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderExperience)("/dyn/tourist/experience");
}



import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderExperience(HTTPContext ctx)
{

debug import std.stdio: writeln;

	//debug writeln(`tourist request headers: `, ctx.request.headers.toAA());

import std.json;
import std.conv: to;
//*************************************************************
JSONValue callParams;

 callParams["currentPage"] = ctx.request.bodyForm.get("currentPage", "1").to!size_t;
 callParams["touristKey"] = ctx.request.queryForm.get("key", null).to!size_t;

//*************************************************************

//dataDict["vpaths"] = Service.virtualPaths;


	auto tpl = Service.templateCache.getByModuleName("mkk.Experience");	
	TDataNode dataDict = mainServiceCall("tourist.experience", ctx, callParams);
	dataDict["vpaths"] = Service.virtualPaths;
	
	return tpl.run(dataDict).str;


}