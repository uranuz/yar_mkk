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
TDataNode renderIndex(HTTPContext ctx)
{
	return TDataNode([
		"pohodList": ctx.mainServiceCall("pohod.recentList")
	]);
}

@IvyModuleAttr(`mkk.AboutSite`)
TDataNode renderAboutSite(HTTPContext ctx) {
	return TDataNode();
}