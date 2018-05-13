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
TDataNode renderObjectList(HTTPContext ctx) {
	return TDataNode(["objectList": mainServiceCall("right.objectList", ctx)]);
}

@IvyModuleAttr(`mkk.Right.ObjectRightList`)
TDataNode renderObjectRightList(HTTPContext ctx)
{
	TDataNode dataDict;
	import std.json: JSONValue;
	import std.conv: to;
	return TDataNode([
		"objectRightList": mainServiceCall("right.objectRightList", ctx,
			JSONValue([
				`num`: ctx.request.form.get("key", null).to!size_t]))
	]);
}