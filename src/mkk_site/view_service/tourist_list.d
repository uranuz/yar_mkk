module mkk_site.view_service.tourist_list;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderTouristList)("/dyn/tourist/list");
	Service.pageRouter.join!(touristPlainList)("/dyn/tourist/plainList");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

import webtank.common.optional: Optional, Undefable;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import mkk_site.data_defs.tourist_list;

string renderTouristList(HTTPContext ctx)
{
	import std.json: JSONValue;

	auto bodyForm = ctx.request.bodyForm;
	TouristListFilter filter;
	formDataToStruct(bodyForm, filter);
	Navigation nav;
	formDataToStruct(bodyForm, nav);

	JSONValue jFilter = filter.toStdJSON();
	TDataNode callResult = mainServiceCall("tourist.list", ctx, JSONValue([
		"filter": jFilter,
		"nav": nav.toStdJSON()
	]));
	TDataNode dataDict = [
		"filter": jFilter.toIvyJSON(),
		"touristList": callResult["rs"],
		"nav": callResult["nav"]
	];

	dataDict["isAuthorized"] = ctx.user.isAuthenticated &&
		( ctx.user.isInRole("moder") || ctx.user.isInRole("admin") );
	dataDict["vpaths"] = Service.virtualPaths;

	return Service.templateCache.getByModuleName("mkk.TouristList").run(dataDict).str;
}

void touristPlainList(HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.algorithm: canFind;

	auto queryForm = ctx.request.queryForm;
	TouristListFilter filter;
	formDataToStruct(queryForm, filter);
	Navigation nav;
	formDataToStruct(queryForm, nav);

	JSONValue jFilter = filter.toStdJSON();
	TDataNode callResult = mainServiceCall("tourist.plainSearch", ctx, JSONValue([
		"filter": jFilter,
		"nav": nav.toStdJSON()
	]));
	TDataNode dataDict = [
		"filter": jFilter.toIvyJSON(),
		"touristList": callResult["rs"],
		"nav": callResult["nav"]
	];

	if( "mode" in queryForm ) {
		if( ["add", "remove"].canFind(queryForm["mode"]) ) {
			dataDict["mode"] = queryForm["mode"];
		}
	}
	if( "instanceName" in queryForm ) {
		dataDict["instanceName"] = queryForm["instanceName"];
	}
	ctx.response.write(
		Service.templateCache.getByModuleName("mkk.TouristPlainList").run(dataDict).str
	);
}

