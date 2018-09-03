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

@IvyModuleAttr(`mkk.IndexPage`)
IvyData renderIndex(HTTPContext ctx)
{
	return IvyData([
		"pohodList": ctx.mainServiceCall("pohod.recentList")
	]);
}

@IvyModuleAttr(`mkk.AboutSite`)
IvyData renderAboutSite(HTTPContext ctx) {
	return IvyData();
}