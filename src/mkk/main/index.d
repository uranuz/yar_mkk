module mkk.main.index;
import mkk.main.devkit;

shared static this() {
	MainService.pageRouter.joinWebFormAPI!(getIndex)("/api/index");
	MainService.pageRouter.joinWebFormAPI!(generalTemplateParams)("/api/generalTemplate/params");
}

import std.typecons: Tuple;
Tuple!(IBaseRecordSet, `pohodList`) getIndex()
{
	import mkk.main.pohod.list: recentPohodList;
	return typeof(return)(recentPohodList());
}

import std.json: JSONValue;
JSONValue generalTemplateParams(HTTPContext ctx)
{
	import mkk.common.utils: getAuthRedirectURI;
	import mkk.main.pohod.filters: getFavoritePohodFilters;
	import std.exception: enforce;
	JSONValue filters = getFavoritePohodFilters();

	JSONValue pl;
	pl["authRedirectURI"] = getAuthRedirectURI(ctx);
	pl["pohodFilterFields"] = filters["allFields"];
	pl["pohodFilterSections"] = filters["sections"];
	return pl;
}
