module mkk_site.view_service.experience;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderExperience)("/dyn/tourist/experience");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import mkk_site.data_defs.common: Navigation;

string renderExperience(HTTPContext ctx)
{
	import std.json;
	import std.conv: to;

	Navigation nav;
	formDataToStruct(ctx.request.bodyForm, nav);
	JSONValue callParams;

	callParams["touristKey"] = ctx.request.queryForm.get("key", null).to!size_t;
	callParams["nav"] = nav.toStdJSON();

	TDataNode dataDict = mainServiceCall("tourist.experience", ctx, callParams);
	dataDict["vpaths"] = Service.virtualPaths;

	return Service.templateCache.getByModuleName("mkk.Experience").run(dataDict).str;
}