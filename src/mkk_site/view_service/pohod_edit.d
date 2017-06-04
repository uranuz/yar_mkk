module mkk_site.view_service.pohod_edit;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderPohodEdit)("/dyn/pohod/edit");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderPohodEdit(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.json;

	auto req = ctx.request;
	auto queryForm = req.queryForm;
	bool isAuthorized = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	
	size_t pohodNum;

	if( queryForm.get("key", null).length == 0 )
	{
		static immutable errorMsg = `<h3>Невозможно отобразить данные похода. Номер похода не задан</h3>`;
		Service.loger.error(errorMsg);
		return errorMsg;
	}

	try {
		pohodNum = queryForm.get("key", null).to!size_t;
	}
	catch( ConvException e )
	{
		static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер похода должен быть целым числом</h3>`;
		Service.loger.error(errorMsg2);
		return errorMsg2;
	}

	TDataNode dataDict;
	dataDict["pohodNum"] = pohodNum;
	dataDict["isAuthorized"] = isAuthorized;

	TDataNode pohodData = mainServiceCall(`pohod.read`, ctx, JSONValue([`pohodNum`: pohodNum]));
	debug import std.stdio;
	debug writeln(`pohodData: `, pohodData);

	dataDict["pohod"] = pohodData;
	//dataDict["extraFileLinks"] = mainServiceCall(`pohod.extraFileLinks`, ctx, JSONValue([`pohodNum`: pohodNum]));
	//dataDict["partyList"] = mainServiceCall(`pohod.partyList`, ctx, JSONValue([`pohodNum`: pohodNum]));
	dataDict["vpaths"] = Service.virtualPaths;

	return Service.templateCache.getByModuleName("mkk.PohodEdit").run(dataDict).str;
}