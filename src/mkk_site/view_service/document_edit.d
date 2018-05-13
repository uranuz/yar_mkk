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

TDataNode documentEditController(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	auto req = ctx.request;
	auto queryForm = req.queryForm;
	auto bodyForm = req.bodyForm;
	Optional!size_t docNum;

	if( "key" in queryForm )
	{
		try {
			docNum = queryForm.get("key", null).to!size_t;
		}
		catch(ConvException e)
		{
			static immutable errorMsg2 = `<h3>Невозможно отобразить данные документа. Номер документа должен быть целым числом</h3>`;
			Service.loger.error(errorMsg2);
			return TDataNode(errorMsg2);
		}
	}

	if( queryForm.get("action", null) == "write" ) {
		return writeDocument(ctx, docNum);
	} else {
		return renderEditDocument(ctx, docNum);
	}
}

TDataNode renderEditDocument(HTTPContext ctx, Optional!size_t docNum)
{
	import std.json: JSONValue;
	import std.datetime: Clock, DateTime;

	TDataNode callResult = mainServiceCall(`document.list`, ctx, JSONValue([
		"filter": JSONValue([
			`nums`: JSONValue(docNum.isSet? [docNum.value]: [])
		]),
		"nav": JSONValue() // Empty placeholder
	]));

	return ViewService.runIvyModule("mkk.DocumentEdit", ctx, TDataNode([
		"document": (!callResult["rs"].empty? callResult["rs"][0]: TDataNode(null))
	]));
}

TDataNode writeDocument(HTTPContext ctx, Optional!size_t docNum)
{
	import std.conv: to, ConvException;
	import std.algorithm: splitter, map, all;
	import std.array: array;
	import std.json: JSONValue;
	import std.datetime: Date;
	import std.string: toLower;

	auto queryForm = ctx.request.queryForm;
	DocumentDataToWrite inputDocData;
	formDataToStruct(queryForm, inputDocData);
	JSONValue newDoc = inputDocData.toStdJSON();

	// Если идентификатор похода не передаётся, то создаётся новый вместо обновления
	if( docNum.isSet ) {
		newDoc["num"] = docNum.value;
	}

	TDataNode dataDict = [
		"errorMsg": TDataNode(null),
		"docNum": docNum.isSet? TDataNode(docNum.value): TDataNode(null),
		"isUpdate": TDataNode(docNum.isSet),
		"instanceName": TDataNode(ctx.request.queryForm.get("instanceName", null))
	];
	try {
		dataDict["docNum"] = mainServiceCall(`document.edit`, ctx, JSONValue([`record`: newDoc])).integer;
	} catch(Exception ex) {
		dataDict["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return ViewService.runIvyModule("mkk.DocumentEdit.Results", ctx, dataDict);
}
