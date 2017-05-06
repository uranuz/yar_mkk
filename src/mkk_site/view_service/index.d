module mkk_site.view_service.index;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderIndex)("/dyn/index");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderIndex(HTTPContext ctx)
{
	auto tpl = Service.templateCache.getByModuleName("mkk.index");
	TDataNode dataDict;
	dataDict["pohodList"] = mainServiceCall("pohod.recentList", ctx);
	dataDict["vpaths"] = Service.virtualPaths;

	return tpl.run(dataDict).str;
}