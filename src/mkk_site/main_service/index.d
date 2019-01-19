module mkk_site.main_service.index;
import mkk_site.main_service.devkit;

shared static this() {
	MainService.pageRouter.joinWebFormAPI!(getIndex)("/api/index");
}

import std.typecons: Tuple;
Tuple!(IBaseRecordSet, `pohodList`) getIndex()
{
	import mkk_site.main_service.pohod.list: recentPohodList;
	return typeof(return)(recentPohodList());
}
