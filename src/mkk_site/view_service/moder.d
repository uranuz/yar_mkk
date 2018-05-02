module mkk_site.view_service.moder;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderModerList)("/dyn/moder/list");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

TDataNode renderModerList(HTTPContext ctx)
{
	TDataNode dataDict;
	dataDict["moderList"] = mainServiceCall("moder.list", ctx);

	return ViewService.runIvyModule("mkk.ModerList", dataDict);
}