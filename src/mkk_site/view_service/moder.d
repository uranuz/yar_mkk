module mkk_site.view_service.moder;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderModerList)("/dyn/moder/list");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

@IvyModuleAttr(`mkk.ModerList`)
IvyData renderModerList(HTTPContext ctx)
{
	return IvyData([
		"moderList": ctx.mainServiceCall("moder.list")
	]);
}