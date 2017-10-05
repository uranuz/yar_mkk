module mkk_site.view_service.controls_test;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/controls_test");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderModerList(HTTPContext ctx)
{
	auto tpl = Service.templateCache.getByModuleName("mkk.controls_test");
	TDataNode dataDict;
	return tpl.run(dataDict).str;
}