module mkk_site.view_service.auth;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderAuth)("/dyn/auth");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

string renderAuth(HTTPContext ctx)
{
	auto tpl = Service.templateCache.getByModuleName("mkk.auth");
	TDataNode dataDict;
	dataDict["auth_msg"] = "";

	return tpl.run(dataDict).str;
}