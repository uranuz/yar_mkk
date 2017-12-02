module mkk_site.view_service.document_list;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

//import std.conv, std.string, std.file, std.array;
//import mkk_site.page_devkit;

shared static this() {
	Service.pageRouter.join!(documentListController)("/dyn/document/list");
}

import ivy;
import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import mkk_site.data_model.document;

TDataNode documentListController(HTTPContext ctx)
{
	import std.json;
	import std.conv: to;

	auto bodyForm = ctx.request.bodyForm;
	DocumentListFilter filter;
	formDataToStruct(bodyForm, filter);
	Navigation nav;
	formDataToStruct(bodyForm, nav);

	JSONValue jFilter = filter.toStdJSON();
	TDataNode callResult = mainServiceCall("document.list", ctx, JSONValue([
		"filter": jFilter,
		"nav": nav.toStdJSON()
	]));
	TDataNode dataDict = [
		"filter": jFilter.toIvyJSON(),
		"documentList": callResult["rs"],
		"nav": callResult["nav"]
	];

	dataDict["isAuthorized"] = ctx.user.isAuthenticated &&
		( ctx.user.isInRole("moder") || ctx.user.isInRole("admin") );
	dataDict["vpaths"] = Service.virtualPaths;

	return Service.templateCache.getByModuleName("mkk.DocumentList").run(dataDict);
}

