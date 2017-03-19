module mkk_site.view_service.pohod;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderPohod)("/dyn/pohod/list");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderPohod(HTTPContext context)
{
	auto tpl = Service.templateCache.getByModuleName("mkk.pohod_navigation");
	TDataNode dataDict;
	dataDict["pohodEnums"] = mainServiceCall("pohod.enumTypes", context);

	return tpl.run(dataDict).str;
}