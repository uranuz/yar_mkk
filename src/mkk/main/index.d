module mkk.main.index;
import mkk.main.devkit;

shared static this() {
	MainService.pageRouter.joinWebFormAPI!(getIndex)("/api/index");
}

import std.typecons: Tuple;
Tuple!(IBaseRecordSet, `pohodList`) getIndex()
{
	import mkk.main.pohod.list: recentPohodList;
	return typeof(return)(recentPohodList());
}
