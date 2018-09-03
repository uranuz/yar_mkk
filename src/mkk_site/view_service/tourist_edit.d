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

IvyData touristEditController(HTTPContext ctx)
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
			return IvyData(errorMsg2);
		}
	}

	if( bodyForm.get("action", null) == "write" ) {
		return writeTourist(ctx);
	} else {
		return renderEditTourist(ctx, touristNum);
	}
}

IvyData renderEditTourist(HTTPContext ctx, Optional!size_t touristNum)
{
	return ViewService.runIvyModule("mkk.TouristEdit", ctx, IvyData([
		"tourist": ctx.mainServiceCall(`tourist.read`, [`touristNum`: touristNum])
	]));
}

IvyData writeTourist(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	TouristDataToWrite record;
	formDataToStruct(ctx.request.form, record);

	IvyData dataDict = [
		"errorMsg": IvyData(null),
		"touristNum": (record.num.isSet?
			IvyData(record.num.value): IvyData(null)),
		"isUpdate": IvyData(record.num.isSet)
	];
	try {
		dataDict["touristNum"] = ctx.mainServiceCall(`tourist.edit`, [`record`: record]).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return ViewService.runIvyModule("mkk.TouristEdit.Results", ctx, dataDict);
}