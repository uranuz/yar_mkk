module mkk_site.view_service.tourist_edit;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;
import mkk_site.data_defs.tourist_edit: TouristDataToWrite;

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.common.optional: Optional, Undefable;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import webtank.common.optional: Undefable, Optional;

shared static this() {
	Service.pageRouter.join!(touristEditController)("/dyn/tourist/edit");
}

string touristEditController(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	auto req = ctx.request;
	auto queryForm = req.queryForm;
	auto bodyForm = req.bodyForm;
	bool isAuthorized = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	Optional!size_t touristNum;

	if( "key" in queryForm )
	{
		try {
			touristNum = queryForm.get("key", null).to!size_t;
		}
		catch(ConvException e)
		{
			static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер туриста должен быть целым числом</h3>`;
			Service.loger.error(errorMsg2);
			return errorMsg2;
		}
	}

	if( bodyForm.get("action", null) == "write" ) {
		return writeTourist(ctx, touristNum, isAuthorized);
	} else {
		return renderEditTourist(ctx, touristNum, isAuthorized);
	}
}

string renderEditTourist(HTTPContext ctx, Optional!size_t touristNum, bool isAuthorized)
{
	import std.json: JSONValue;
	TDataNode dataDict;

	dataDict["isAuthorized"] = isAuthorized;
	dataDict["tourist"] = mainServiceCall(`tourist.read`, ctx, JSONValue([`touristNum`: touristNum.toStdJSON()]));
	dataDict["vpaths"] = Service.virtualPaths;

	return Service.templateCache.getByModuleName("mkk.TouristEdit").run(dataDict).str;
}

string writeTourist(HTTPContext ctx, Optional!size_t touristNum, bool isAuthorized)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	auto bodyForm = ctx.request.bodyForm;
	TouristDataToWrite inputTouristData;
	formDataToStruct(bodyForm, inputTouristData);
	JSONValue newTourist = inputTouristData.toStdJSON();

	// Если идентификатор похода не передаётся, то создаётся новый вместо обновления
	if( touristNum.isSet ) {
		newTourist["num"] = touristNum.value;
	}

	TDataNode dataDict = [
		"errorMsg": TDataNode(null),
		"touristNum": touristNum.isSet? TDataNode(touristNum.value): TDataNode(null),
		"isUpdate": TDataNode(touristNum.isSet)
	];
	try {
		dataDict["touristNum"] = mainServiceCall(`tourist.edit`, ctx, JSONValue([`record`: newTourist])).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return Service.templateCache.getByModuleName("mkk.TouristEdit.Results").run(dataDict).str;
}