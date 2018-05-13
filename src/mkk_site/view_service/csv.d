module mkk_site.view_service.csv;
import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(statCsv)("/dyn/stat.csv");
	ViewService.pageRouter.join!(pohodCsv)("/dyn/pohod.csv");

}


import webtank.net.http.handler;
import webtank.net.http.context;

import mkk_site.data_model.stat;
import mkk_site.data_model.pohod_list;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

void statCsv(HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.conv: to;
//*************************************************************	auto bodyForm = ctx.request.bodyForm;
	auto bodyForm = ctx.request.bodyForm;
	StatSelect select;
	formDataToStruct(bodyForm, select);
	
//**************************************************************
	//lданные для передачи в в основной сервис
	string csv = mainServiceCall("stat.Csv", ctx, JSONValue([
		"select": select.toStdJSON()
	])).to!string;

	ctx.response.headers["Content-Type"]=`text/csv; charset="utf-8`;
	ctx.response.write(csv);
	
}

void pohodCsv (HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.conv: to;
	import std.stdio;
//*************************************************************
	writeln(`bodyForm:`, ctx.request.bodyForm);
	auto bodyForm = ctx.request.bodyForm;
	PohodFilter filter;
	formDataToStruct(bodyForm, filter);
	writeln(`formDataToStruct:`, filter);
	
//**************************************************************
	//lданные для передачи в в основной сервис
     string csv = mainServiceCall("pohod.Csv", ctx, JSONValue([
		"filter": filter.toStdJSON()
		])).to!string;
    import std.stdio;
	//string csv=">.>.>.>.>.>.";
	writeln(ctx.request.messageBody);
	ctx.response.headers["Content-Type"]=`text/csv; charset="utf-8`;
	ctx.response.write(csv);
}