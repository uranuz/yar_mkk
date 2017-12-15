module mkk_site.view_service.index;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderIndex)("/dyn/index");
	Service.pageRouter.join!(renderAboutSite)("/dyn/about");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

TDataNode renderIndex(HTTPContext ctx)
{
	TDataNode dataDict;
	dataDict["pohodList"] = mainServiceCall("pohod.recentList", ctx);
	dataDict["vpaths"] = Service.virtualPaths;

	return Service.templateCache.getByModuleName("mkk.IndexPage").run(dataDict);
}

TDataNode renderAboutSite(HTTPContext ctx) {
	return Service.templateCache.getByModuleName("mkk.AboutSite").run();
}