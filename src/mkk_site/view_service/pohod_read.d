module mkk_site.view_service.pohod_read;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderPohodRead)("/dyn/pohod/read");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderPohodRead(HTTPContext ctx)
{
	import std.conv: to, ConvException;
	import std.json;

	auto req = ctx.request;
	auto queryForm = req.queryForm;
	bool isAuthorized = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	
	size_t pohodKey;

	if( queryForm.get("key", null).length == 0 )
	{
		static immutable errorMsg = `<h3>Невозможно отобразить данные похода. Номер похода не задан</h3>`;
		Service.loger.error(errorMsg);
		return errorMsg;
	}

	try {
		pohodKey = queryForm.get("key", null).to!size_t;
	}
	catch( ConvException e )
	{
		static immutable errorMsg2 = `<h3>Невозможно отобразить данные похода. Номер похода должен быть целым числом</h3>`;
		Service.loger.error(errorMsg2);
		return errorMsg2;
	}

	TDataNode dataDict;
	dataDict["pohodKey"] = pohodKey;
	dataDict["isAuthorized"] = isAuthorized;
	dataDict["pohod"] = mainServiceCall(`pohod.read`, ctx, JSONValue([`pohodKey`: pohodKey]));
	dataDict["extraFileLinks"] = mainServiceCall(`pohod.read`, ctx, JSONValue([`pohodKey`: pohodKey]));
	//auto touristList = getPohodParticipants(pohodKey);

	return Service.templateCache.getByModuleName("mkk.PohodRead").run(dataDict).str;
}