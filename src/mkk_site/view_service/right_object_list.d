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

TDataNode renderObjectList(HTTPContext ctx)
{
	TDataNode dataDict;
	dataDict["objectList"] = mainServiceCall("right.objectList", ctx);

	return ViewService.runIvyModule("mkk.Right.ObjectList", dataDict);
}

TDataNode renderObjectRightList(HTTPContext ctx)
{
	TDataNode dataDict;
	import std.json: JSONValue;
	import std.conv: text;
	dataDict["objectRightList"] = mainServiceCall("right.objectRightList", ctx, JSONValue(ctx.request.form.get("key", null).text));

	return ViewService.runIvyModule("mkk.Right.ObjectRightList", dataDict);
}