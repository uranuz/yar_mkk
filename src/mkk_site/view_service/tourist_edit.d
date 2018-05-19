module mkk_site.view_service.tourist_edit;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;
import mkk_site.data_model.tourist_edit: TouristDataToWrite;

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.common.optional: Optional, Undefable;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import webtank.common.optional: Undefable, Optional;

shared static this() {
	ViewService.pageRouter.join!(touristEditController)("/dyn/tourist/edit");
}

TDataNode touristEditController(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	auto req = ctx.request;
	auto queryForm = req.queryForm;
	auto bodyForm = req.bodyForm;
	Optional!size_t touristNum;

	if( "num" in queryForm )
	{
		try {
			touristNum = queryForm.get("num", null).to!size_t;
		}
		catch(ConvException e)
		{
			static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер туриста должен быть целым числом</h3>`;
			Service.loger.error(errorMsg2);
			return TDataNode(errorMsg2);
		}
	}

	if( bodyForm.get("action", null) == "write" ) {
		return writeTourist(ctx);
	} else {
		return renderEditTourist(ctx, touristNum);
	}
}

TDataNode renderEditTourist(HTTPContext ctx, Optional!size_t touristNum)
{
	return ViewService.runIvyModule("mkk.TouristEdit", ctx, TDataNode([
		"tourist": ctx.mainServiceCall(`tourist.read`, [`touristNum`: touristNum])
	]));
}

TDataNode writeTourist(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	TouristDataToWrite record;
	formDataToStruct(ctx.request.form, record);

	TDataNode dataDict = [
		"errorMsg": TDataNode(null),
		"touristNum": (record.num.isSet?
			TDataNode(record.num.value): TDataNode(null)),
		"isUpdate": TDataNode(record.num.isSet)
	];
	try {
		dataDict["touristNum"] = ctx.mainServiceCall(`tourist.edit`, [`record`: record]).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return ViewService.runIvyModule("mkk.TouristEdit.Results", ctx, dataDict);
}