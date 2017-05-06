module mkk_site.view_service.moder;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/moder/list");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderModerList(HTTPContext ctx)
{
	debug import std.stdio: writeln;

	debug writeln(`moder request headers: `, ctx.request.headers.toAA());
	
	auto tpl = Service.templateCache.getByModuleName("mkk.ModerList");
	TDataNode dataDict;

	dataDict["moder_list"] = mainServiceCall("moder.list", ctx);

	return tpl.run(dataDict).str;
}