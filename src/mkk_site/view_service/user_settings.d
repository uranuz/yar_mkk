module mkk_site.view_service.user_settings;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderUserSettings)("/dyn/user_settings");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

@IvyModuleAttr(`mkk.UserSettings`)
IvyData renderUserSettings(HTTPContext ctx)
{
	IvyData dataDict = [
		`userFullName`: IvyData(ctx.user.name),
		`userLogin`: IvyData(ctx.user.id),
		`pwChangeMessage`: IvyData(null)
	];

	try
	{
		ctx.mainServiceCall("user.changePassword", [
			`oldPassword`: ctx.request.bodyForm.get(`oldPassword`, null),
			`newPassword`: ctx.request.bodyForm.get(`newPassword`, null),
			`repeatPassword`: ctx.request.bodyForm.get(`repeatPassword`, null),
		]);
	} catch(Exception ex) {
		dataDict[`pwChangeMessage`] = ex.msg;
	}

	return dataDict;
}