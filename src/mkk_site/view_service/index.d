module mkk_site.view_service.index;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderIndex)("/dyn/index");
	ViewService.pageRouter.join!(renderAboutSite)("/dyn/about");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

TDataNode renderIndex(HTTPContext ctx)
{
	TDataNode dataDict;
	dataDict["pohodList"] = mainServiceCall("pohod.recentList", ctx);
	dataDict["vpaths"] = Service.virtualPaths;

	return ViewService.templateCache.getByModuleName("mkk.IndexPage").run(dataDict);
}

TDataNode renderAboutSite(HTTPContext ctx) {
	return ViewService.templateCache.getByModuleName("mkk.AboutSite").run();
}