module mkk_site.view_service.user_list;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderUserList)("/dyn/user/list");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

@IvyModuleAttr(`mkk.UserList`, `UserList`)
IvyData renderUserList(HTTPContext ctx)
{
	return IvyData([
		"userList": ctx.mainServiceCall("user.list")
	]);
}