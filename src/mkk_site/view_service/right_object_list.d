module mkk_site.view_service.right_object_list;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(renderObjectList)("/dyn/right/object/list");
	ViewService.pageRouter.join!(renderObjectRightList)("/dyn/right/object/right/list");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;

@IvyModuleAttr(`mkk.Right.ObjectList`)
IvyData renderObjectList(HTTPContext ctx) {
	return IvyData(["objectList": ctx.mainServiceCall("right.objectList")]);
}

@IvyModuleAttr(`mkk.Right.ObjectRightList`)
IvyData renderObjectRightList(HTTPContext ctx)
{
	IvyData dataDict;
	import std.conv: to;
	return IvyData([
		"objectRightList": ctx.mainServiceCall("right.objectRightList", [
			`num`: ctx.request.form.get("num", null).to!size_t
		])
	]);
}