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
	auto tpl = Service.templateCache.getByModuleName("mkk.moder_list");
	TDataNode dataDict;
	dataDict["moder_list"] = callMainServiceMethodAndWaitAsIvyNode("moder.list");

	return tpl.run(dataDict).str;
}