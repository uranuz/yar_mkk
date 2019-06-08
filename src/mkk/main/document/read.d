module mkk.main.document.read;

import mkk.main.devkit;
import mkk.main.document.model;

shared static this()
{
	MainService.JSON_RPCRouter.join!(readDocument)(`document.read`);

	MainService.pageRouter.joinWebFormAPI!(readDocument)("/api/document/read");
}

import std.typecons: Tuple;

/// Возвращает информацию о документе по идентификатору
Tuple!(IBaseRecord, `document`)
readDocument(HTTPContext ctx, Optional!size_t num)
{
	import mkk.main.document.list: getDocumentList;
	DocumentListFilter filter;
	Navigation nav;
	if( num.isSet ) {
		filter.nums = [num.value];
	} else {
		filter.nums = [];
	}
	// Для чтения документа используем метод списка, который поддерживает фильтрацию по списку идентификаторов
	auto res = getDocumentList(ctx, filter, nav);

	return typeof(return)(res.documentList && res.documentList.length? res.documentList[0]: null);
}