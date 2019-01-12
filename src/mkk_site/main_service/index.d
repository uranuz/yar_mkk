module mkk_site.main_service.index;
import mkk_site.main_service.devkit;

shared static this() {
	MainService.pageRouter.joinWebFormAPI!(renderIndex)("/api/index");
}

import std.json: JSONValue;

import mkk_site.main_service.pohod_list: recentPohodList;

JSONValue renderIndex(HTTPContext ctx)
{
	return JSONValue([
		"pohodList": recentPohodList().toStdJSON()
	]);
}
