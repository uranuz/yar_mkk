module mkk_site.view_service.pohod_edit;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(pohodEditController)("/dyn/pohod/edit");
	Service.pageRouter.join!(tousristPlainList)("/dyn/tourist/plainList");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.common.optional: Optional;

string pohodEditController(HTTPContext ctx)
{
	import std.conv: to, ConvException;

	auto req = ctx.request;
	auto queryForm = req.queryForm;
	auto bodyForm = req.bodyForm;
	bool isAuthorized = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	Optional!size_t pohodNum;
	if( "key" in queryForm )
	{
		try {
			pohodNum = queryForm.get("key", null).to!size_t;
		}
		catch(ConvException e)
		{
			static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер похода должен быть целым числом</h3>`;
			Service.loger.error(errorMsg2);
			return errorMsg2;
		}
	}

	if( bodyForm.get("action", null) == "write" ) {
		return writePohod(ctx, pohodNum, isAuthorized);
	} else {
		return renderEditPohod(ctx, pohodNum, isAuthorized);
	}
}

string renderEditPohod(HTTPContext ctx, Optional!size_t pohodNum, bool isAuthorized)
{
	import std.json: JSONValue;
	TDataNode dataDict;
	if( pohodNum.isSet )
	{
		dataDict["isAuthorized"] = isAuthorized;
		dataDict["pohod"] = mainServiceCall(`pohod.read`, ctx, JSONValue([`pohodNum`: pohodNum.value]));
		//dataDict["extraFileLinks"] = mainServiceCall(`pohod.extraFileLinks`, ctx, JSONValue([`num`: pohodNum]));
		dataDict["partyList"] = mainServiceCall(`pohod.partyList`, ctx, JSONValue([`num`: pohodNum]));
		dataDict["vpaths"] = Service.virtualPaths;
	}

	return Service.templateCache.getByModuleName("mkk.PohodEdit").run(dataDict).str;
}

string writePohod(HTTPContext ctx, Optional!size_t pohodNum, bool isAuthorized)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	auto bodyForm = ctx.request.bodyForm;
	
	static immutable allStringFields = [
		"mkkCode", "bookNum", "mkkComment", "pohodRegion", "route", "chiefComment", "organization", "partyRegion"
	];
	JSONValue newPohod;
	foreach( fieldName; allStringFields )
	{
		if( fieldName in bodyForm ) {
			newPohod[fieldName] = bodyForm[fieldName];
		}
	}

	foreach( fieldName; ["claimState", "tourismKind", "complexity", "complexityElems", "progress"] )
	{
		if( fieldName !in bodyForm )
			continue;

		string strKey = bodyForm[fieldName];
		if( strKey.length != 0 && toLower(strKey) != "null" )
		{
			try {
				newPohod[fieldName] = strKey.to!int;
			} catch (std.conv.ConvException e) {
				throw new std.conv.ConvException("Выражение \"" ~ strKey ~ "\" не является значением типа \"" ~ fieldName ~ "\"!!!");
			}
		} else {
			newPohod[fieldName] = null;
		}
	}

	foreach( fieldPrefix; ["begin", "finish"] )
	{
		string[] dateFields = ["day", "month", "year"].map!((b) => fieldPrefix ~ "__" ~ b).array;
		if( !all!( (a) => cast(bool)(a in bodyForm) )(dateFields) ) {
			continue;
		}

		if( !all!(
				(a) => (bodyForm[a].length == 0 || bodyForm[a].toLower() == "null")
			)(dateFields)
		) {
			Date pohodDate;
			try {
				pohodDate = Date(
					bodyForm[fieldPrefix ~ "__year"].to!int,
					bodyForm[fieldPrefix ~ "__month"].to!int,
					bodyForm[fieldPrefix ~ "__day"].to!int,
				);
			} catch(ConvException) {
				throw new Exception("Неправильный формат даты похода");
			}
			newPohod[fieldPrefix ~ "__date"] = pohodDate.toISOExtString();
		} else {
			newPohod[fieldPrefix ~ "__date"] = null;
		}
	}

	if( "partyNums" in bodyForm )
	{
		if( bodyForm["partyNums"] != "null" && bodyForm["partyNums"].length != 0 ) {
			try {
				newPohod["partyNum"] = bodyForm["partyNums"].splitter(",").map!( (a) => a.to!size_t ).array;
			} catch(ConvException) {
				throw new Exception("Передан некорректный список идентификаторов туристов");
			}
		} else {
			newPohod["partyNum"] = null;
		}
	}

	// Если идентификатор похода не передаётся, то создаётся новый вместо обновления
	if( pohodNum.isSet ) {
		newPohod["num"] = pohodNum.value;
	}

	TDataNode dataDict = [
		"errorMsg": TDataNode(null),
		"pohodNum": pohodNum.isSet? TDataNode(pohodNum.value): TDataNode(null)
	];
	try {
		TDataNode pohodData = mainServiceCall(`pohod.edit`, ctx, newPohod);
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return Service.templateCache.getByModuleName("mkk.PohodEdit.Results").run(dataDict).str;
}

void tousristPlainList(HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.algorithm: map, splitter, canFind;
	import std.conv: to;
	import std.array: array;
	auto queryForm = ctx.request.queryForm;
	JSONValue filter;
	static immutable string[] strFieldNames = [
		"familyName", "givenName", "patronymic", "region", "city", "street"
	];
	
	if( "keys" in queryForm )
	{
		if( queryForm["keys"] != "null" && queryForm["keys"].length > 0 ) {
			filter["nums"] = queryForm["keys"].splitter(",").map!( (a) => a.to!size_t ).array;
		} else {
			filter["nums"] = null;
		}
	}
	foreach( fieldName; strFieldNames )
	{
		if( fieldName in queryForm )
		{
			if( queryForm[fieldName].length > 0 ) {
				filter[fieldName] = queryForm[fieldName];
			} else {
				filter[fieldName] = null;
			}
		}
	}
	if( "birthYear" in queryForm )
	{
		if( queryForm["birthYear"] != "null" && queryForm["birthYear"].length > 0 ) {
			filter["birthYear"] = queryForm["birthYear"].to!size_t;
		} else {
			filter["birthYear"] = null;
		}
	}
	TDataNode callResult = mainServiceCall("tourist.plainSearch", ctx, JSONValue([
		"filter": filter, "nav": JSONValue([
			"offset": 0,
			"pageSize": 10
		])
	]));
	TDataNode dataDict = [
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