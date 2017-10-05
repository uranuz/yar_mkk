module mkk_site.view_service.moder;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/moder/list");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderModerList(HTTPContext ctx)
{
	auto tpl = Service.templateCache.getByModuleName("mkk.ModerList");
	TDataNode dataDict;

	dataDict["moderList"] = mainServiceCall("moder.list", ctx);

	return tpl.run(dataDict).str;
}