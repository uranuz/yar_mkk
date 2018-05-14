module mkk_site.view_service.pohod_edit;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;
import mkk_site.data_model.pohod_edit: PohodDataToWrite;
import mkk_site.common.utils: getAuthRedirectURI;

shared static this() {
	ViewService.pageRouter.join!(pohodEditController)("/dyn/pohod/edit");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.common.optional: Optional, Undefable;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

TDataNode pohodEditController(HTTPContext ctx)
{
	import std.conv: to, ConvException;

	auto req = ctx.request;
	auto queryForm = req.queryForm;
	auto bodyForm = req.bodyForm;
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
			return TDataNode(errorMsg2);
		}
	}

	if( bodyForm.get("action", null) == "write" ) {
		return writePohod(ctx, pohodNum);
	} else {
		return renderEditPohod(ctx, pohodNum);
	}
}

TDataNode renderEditPohod(HTTPContext ctx, Optional!size_t pohodNum)
{
	import std.json: JSONValue;
	TDataNode dataDict;

	dataDict["pohod"] = ctx.mainServiceCall(`pohod.read`, [`pohodNum`: pohodNum]);
	dataDict["extraFileLinks"] = ctx.mainServiceCall(`pohod.extraFileLinks`, [`num`: pohodNum]);
	dataDict["partyList"] = ctx.mainServiceCall(`pohod.partyList`, [`num`: pohodNum]);
	dataDict["authRedirectURI"] = getAuthRedirectURI(ctx);

	return ViewService.runIvyModule("mkk.PohodEdit", ctx, dataDict);
}

TDataNode writePohod(HTTPContext ctx, Optional!size_t pohodNum)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	auto bodyForm = ctx.request.bodyForm;
	PohodDataToWrite inputPohodData;
	formDataToStruct(bodyForm, inputPohodData);
	JSONValue newPohod = inputPohodData.toStdJSON();

	// Если идентификатор похода не передаётся, то создаётся новый вместо обновления
	if( pohodNum.isSet ) {
		newPohod["num"] = pohodNum.value;
	}

	TDataNode dataDict = [
		"errorMsg": TDataNode(null),
		"pohodNum": pohodNum.isSet? TDataNode(pohodNum.value): TDataNode(null),
		"isUpdate": TDataNode(pohodNum.isSet)
	];
	try {
		dataDict["pohodNum"] = ctx.mainServiceCall(`pohod.edit`, [`record`: newPohod]).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return ViewService.runIvyModule("mkk.PohodEdit.Results", ctx, dataDict);
}