module mkk_site.view_service.pohod_read;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderPohodRead)("/dyn/pohod/read");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

@IvyModuleAttr(`mkk.PohodRead`)
IvyData renderPohodRead(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.json;
	import std.exception: enforce;

	auto req = ctx.request;
	auto queryForm = req.queryForm;
	enforce( queryForm["num"].length, `Невозможно отобразить данные похода. Номер похода не задан` );

	size_t pohodNum;
	try {
		pohodNum = queryForm["num"].to!size_t;
	} catch( ConvException e ) {
		throw new Exception(`Невозможно отобразить данные похода. Номер похода должен быть целым числом`);
	}

	return IvyData([
		"pohodNum": IvyData(pohodNum),
		"pohod": ctx.mainServiceCall(`pohod.read`, [`pohodNum`: pohodNum]),
		"extraFileLinks": ctx.mainServiceCall(`pohod.extraFileLinks`, [`num`: pohodNum]),
		"partyList": ctx.mainServiceCall(`pohod.partyList`, [`num`: pohodNum])
	]);
}