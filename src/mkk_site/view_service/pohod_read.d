module mkk_site.view_service.pohod_read;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderPohodRead)("/dyn/pohod/read");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

TDataNode renderPohodRead(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.json;
	import std.exception: enforce;

	auto req = ctx.request;
	auto queryForm = req.queryForm;
	enforce( queryForm["key"].length, `Невозможно отобразить данные похода. Номер похода не задан` );

	size_t pohodNum;
	try {
		pohodNum = queryForm["key"].to!size_t;
	} catch( ConvException e ) {
		throw new Exception(`Невозможно отобразить данные похода. Номер похода должен быть целым числом`);
	}

	TDataNode dataDict;
	dataDict["pohodNum"] = pohodNum;
	dataDict["isAuthorized"] = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	dataDict["pohod"] = mainServiceCall(`pohod.read`, ctx, JSONValue([`pohodNum`: pohodNum]));
	dataDict["extraFileLinks"] = mainServiceCall(`pohod.extraFileLinks`, ctx, JSONValue([`num`: pohodNum]));
	dataDict["partyList"] = mainServiceCall(`pohod.partyList`, ctx, JSONValue([`num`: pohodNum]));
	dataDict["vpaths"] = Service.virtualPaths;

	return ViewService.runIvyModule("mkk.PohodRead", ctx, dataDict);
}