module mkk_site.view_service.stat;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderStat)("/dyn/stat");
}


import ivy.interpreter_data, ivy.json, ivy.interpreter;
import webtank.net.http.handler;
import webtank.net.http.context;

import mkk_site.data_defs.stat;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

	string renderStat(HTTPContext ctx)
{
	debug import std.stdio: writeln;
	debug writeln(`document request headers: `, ctx.request.headers.toAA());
	
	import std.json: JSONValue;
	import std.conv: to;
//*************************************************************	auto bodyForm = ctx.request.bodyForm;
	auto bodyForm = ctx.request.bodyForm;
	StatSelect select;
	formDataToStruct(bodyForm, select);
	JSONValue jSelect = select.toStdJSON();	
	
//**************************************************************
	//lданные для передачи в в основной сервис

	TDataNode dataDict = [
		"select": jSelect.toIvyJSON(),
		"data": mainServiceCall("stat.Data", ctx, JSONValue(["select":jSelect]))
	];	
	//lданные для передачи в шаблон

	return Service.templateCache.getByModuleName("mkk.Stat").run(dataDict).str;
}