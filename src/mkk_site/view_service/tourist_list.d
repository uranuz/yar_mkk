module mkk_site.view_service.tourist_list;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderTouristList)("/dyn/tourist/list");
	ViewService.pageRouter.join!(touristPlainList)("/dyn/tourist/plainList");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

import webtank.common.optional: Optional, Undefable;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import mkk_site.data_model.tourist_list;

@IvyModuleAttr(`mkk.TouristList`)
IvyData renderTouristList(HTTPContext ctx)
{
	import std.json: JSONValue;
	auto bodyForm = ctx.request.bodyForm;
	TouristListFilter filter;
	Navigation nav;

	formDataToStruct(bodyForm, filter);
	formDataToStruct(bodyForm, nav);

	JSONValue jFilter = filter.toStdJSON();
	IvyData callResult = ctx.mainServiceCall("tourist.list", [
		"filter": jFilter,
		"nav": nav.toStdJSON()
	]);

	return IvyData([
		"filter": jFilter.toIvyJSON(),
		"touristList": callResult["rs"],
		"nav": callResult["nav"]
	]);
}

@IvyModuleAttr(`mkk.TouristPlainList`)
IvyData touristPlainList(HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.algorithm: canFind;

	auto queryForm = ctx.request.queryForm;
	TouristListFilter filter;
	formDataToStruct(queryForm, filter);
	Navigation nav;
	formDataToStruct(queryForm, nav);

	JSONValue jFilter = filter.toStdJSON();
	IvyData callResult = ctx.mainServiceCall("tourist.plainSearch", [
		"filter": jFilter,
		"nav": nav.toStdJSON()
	]);
	IvyData dataDict = [
		"filter": jFilter.toIvyJSON(),
		"touristList": callResult["rs"],
		"nav": callResult["nav"]
	];

	if( auto it = "mode" in queryForm ) {
		if( ["add", "remove"].canFind(*it) ) {
			dataDict["mode"] = *it;
		}
	}
	if( auto it = "instanceName" in queryForm ) {
		dataDict["instanceName"] = *it;
	}

	return dataDict;
}

