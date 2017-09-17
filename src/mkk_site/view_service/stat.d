module mkk_site.view_service.stat;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/stat");
}


import ivy.interpreter_data, ivy.json, ivy.interpreter;
import webtank.net.http.handler;
import webtank.net.http.context;

	string renderModerList(HTTPContext ctx)
{
	debug import std.stdio: writeln;
	debug writeln(`document request headers: `, ctx.request.headers.toAA());
	
	import std.json;
	import std.conv: to;
//*************************************************************
	JSONValue callParams;
	
			callParams["on_years"] = ctx.request.bodyForm.get("on_years", "checked");
			callParams["on_KC"] = ctx.request.bodyForm.get("on_KC", "");
			callParams ["kodMKK"] = ctx.request.bodyForm.get("kodMKK", "176-00");
			callParams["organization"] = ctx.request.bodyForm.get("organization", "");
			callParams["territory"] = ctx.request.bodyForm.get("territory", "");
		
	
//**************************************************************
	auto tpl = Service.templateCache.getByModuleName("mkk.Stat");	
	TDataNode dataDict = mainServiceCall("stat.Data", ctx, callParams);
	dataDict["vpaths"] = Service.virtualPaths;

	//dataDict["isAuthenticated"] = true;


	return tpl.run(dataDict).str;
}