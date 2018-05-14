module mkk_site.view_service.experience;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderExperience)("/dyn/tourist/experience");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import mkk_site.data_model.common: Navigation;

@IvyModuleAttr(`mkk.Experience`)
TDataNode renderExperience(HTTPContext ctx)
{
	import std.json;
	import std.conv: to, ConvException;
	import std.exception: enforce;

	Navigation nav;
	formDataToStruct(ctx.request.bodyForm, nav);
	auto queryForm = ctx.request.queryForm;

	enforce( queryForm["key"].length, `Невозможно отобразить данные туриста. Номер туриста не задан` );

	size_t touristNum;
	try {
		touristNum = queryForm["key"].to!size_t;
	} catch( ConvException e ) {
		throw new Exception(`Невозможно отобразить данные туриста. Номер туриста должен быть целым числом`);
	}

	return ctx.mainServiceCall("tourist.experience", [
		"touristKey": JSONValue(touristNum),
		"nav": nav.toStdJSON()
	]);
}