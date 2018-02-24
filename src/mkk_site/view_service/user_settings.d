module mkk_site.view_service.user_settings;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderUserSettings)("/dyn/user_settings");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

TDataNode renderUserSettings(HTTPContext ctx)
{
	import std.json: JSONValue;

	TDataNode dataDict = [
		`userFullName`: TDataNode(ctx.user.name),
		`userLogin`: TDataNode(ctx.user.id),
		`pwChangeMessage`: TDataNode(null)
	];

	try
	{
		mainServiceCall("user.changePassword", ctx, JSONValue([
			`oldPassword`: ctx.request.bodyForm.get(`oldPassword`, null),
			`newPassword`: ctx.request.bodyForm.get(`newPassword`, null),
			`repeatPassword`: ctx.request.bodyForm.get(`repeatPassword`, null),
		]));
	} catch(Exception ex) {
		dataDict[`pwChangeMessage`] = ex.msg;
	}

	return ViewService.templateCache.getByModuleName("mkk.UserSettings").run(dataDict);
}