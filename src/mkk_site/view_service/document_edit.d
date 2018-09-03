module mkk_site.view_service.document_edit;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;
import mkk_site.data_model.document: DocumentDataToWrite;
import mkk_site.common.utils: getAuthRedirectURI;

shared static this() {
	ViewService.pageRouter.join!(documentEditController)("/dyn/document/edit");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.common.optional: Optional, Undefable;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

IvyData documentEditController(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	auto req = ctx.request;
	auto queryForm = req.queryForm;
	auto bodyForm = req.bodyForm;
	Optional!size_t docNum;

	if( "num" in queryForm )
	{
		try {
			docNum = queryForm.get("num", null).to!size_t;
		}
		catch(ConvException e)
		{
			static immutable errorMsg2 = `<h3>Невозможно отобразить данные документа. Номер документа должен быть целым числом</h3>`;
			Service.loger.error(errorMsg2);
			return IvyData(errorMsg2);
		}
	}

	if( queryForm.get("action", null) == "write" ) {
		return writeDocument(ctx, docNum);
	} else {
		return renderEditDocument(ctx, docNum);
	}
}

IvyData renderEditDocument(HTTPContext ctx, Optional!size_t docNum)
{
	import std.json: JSONValue;
	import std.datetime: Clock, DateTime;

	IvyData callResult = ctx.mainServiceCall(`document.list`, [
		"filter": JSONValue([
			`nums`: docNum.isSet? [docNum.value]: null
		]),
		"nav": JSONValue() // Empty placeholder
	]);

	return ViewService.runIvyModule("mkk.DocumentEdit", ctx, IvyData([
		"document": (!callResult["rs"].empty? callResult["rs"][0]: IvyData(null))
	]));
}

IvyData writeDocument(HTTPContext ctx, Optional!size_t docNum)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.datetime: Date;
	import std.string: toLower;

	DocumentDataToWrite inputDocData;
	formDataToStruct(ctx.request.form, inputDocData);

	IvyData dataDict = [
		"errorMsg": IvyData(null),
		"docNum": docNum.isSet? IvyData(docNum.value): IvyData(null),
		"isUpdate": IvyData(docNum.isSet),
		"instanceName": IvyData(ctx.request.form.get("instanceName", null))
	];
	try {
		dataDict["docNum"] = ctx.mainServiceCall(`document.edit`, [`record`: inputDocData]).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return ViewService.runIvyModule("mkk.DocumentEdit.Results", ctx, dataDict);
}
