module mkk_site.view_service.user_settings;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderModerList)("/dyn/user_settings");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderModerList(HTTPContext ctx)
{
	TDataNode dataDict = [
		`userFullName`: TDataNode(ctx.user.name),
		`userLogin`: TDataNode(ctx.user.id),
		`pwChangeMessage`: TDataNode(null)
	];

	try {
		mainServiceCall("moder.list", ctx);
	} catch(Exception ex) {
		dataDict[`pwChangeMessage`] = ex.msg;
	}

	return Service.templateCache.getByModuleName("mkk.UserSettings").run(dataDict).str;
}