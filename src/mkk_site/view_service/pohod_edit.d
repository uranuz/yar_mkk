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
	Optional!size_t pohodNum;
	if( "num" in req.form )
	{
		try {
			pohodNum = req.form.get("num", null).to!size_t;
		}
		catch(ConvException e)
		{
			static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер похода должен быть целым числом</h3>`;
			Service.loger.error(errorMsg2);
			return TDataNode(errorMsg2);
		}
	}

	if( req.form.get("action", null) == "write" ) {
		return writePohod(ctx);
	} else {
		return renderEditPohod(ctx, pohodNum);
	}
}

TDataNode renderEditPohod(HTTPContext ctx, Optional!size_t pohodNum)
{
	return ViewService.runIvyModule("mkk.PohodEdit", ctx, TDataNode([
		"pohod": ctx.mainServiceCall(`pohod.read`, [`pohodNum`: pohodNum]),
		"extraFileLinks": ctx.mainServiceCall(`pohod.extraFileLinks`, [`num`: pohodNum]),
		"partyList": ctx.mainServiceCall(`pohod.partyList`, [`num`: pohodNum]),
		"authRedirectURI": TDataNode(getAuthRedirectURI(ctx))
	]));
}

TDataNode writePohod(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	PohodDataToWrite record;
	formDataToStruct(ctx.request.form, record);
	TDataNode dataDict = [
		"errorMsg": TDataNode(null),
		"pohodNum": (record.num.isSet?
			TDataNode(record.num.value): TDataNode(null)),
		"isUpdate": TDataNode(record.num.isSet)
	];
	try {
		dataDict["pohodNum"] = ctx.mainServiceCall(`pohod.edit`, [`record`: record]).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return ViewService.runIvyModule("mkk.PohodEdit.Results", ctx, dataDict);
}