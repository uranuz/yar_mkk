module mkk.main.document.edit;

import mkk.main.devkit;
import mkk.main.document.model;

shared static this()
{
	MainService.JSON_RPCRouter.join!(writeDocument)(`document.edit`);
	MainService.JSON_RPCRouter.join!(deleteDocument)(`document.delete`);

	MainService.pageRouter.joinWebFormAPI!(writeDocument)("/api/document/edit/results");
}

Tuple!(Optional!size_t, "documentNum")
writeDocument(HTTPContext ctx, DocumentDataToWrite record)
{
	import webtank.security.right.access_exception: AccessException;

	enforce!AccessException(
		ctx.rights.hasRight(`document.item`, `edit`),
		`Недостаточно прав для редактирования ссылки на документ!`);
	checkStructEditRights(record, ctx);

	string[] fieldNames;
	string[] fieldValues;
	mixin(WalkFields!(`record`, q{
		fieldNames ~= dbFieldName;
		fieldValues ~= field.toPGString();
	}));

	auto res = typeof(return)(record.num);
	if( fieldNames.empty ) {
		return res;
	}

	ctx.service.log.info("Формирование и выполнение запроса к БД", "Изменение ссылки на документ");
	res.documentNum = getCommonDB().insertOrUpdateTableByNum(`file_link`, fieldNames, fieldValues, record.num);
	ctx.service.log.info("Выполнение запроса к БД завершено", "Изменение ссылки на документ");

	return res;
}

/++ Простой, но опасный метод, который удаляет сылку на документ по ключу. +/
void deleteDocument(HTTPContext ctx, size_t num)
{
	import webtank.security.right.access_exception: AccessException;

	enforce!AccessException(
		ctx.rights.hasRight(`document.item`, `delete`),
		`Недостаточно прав для удаления документа!`);

	getCommonDB().queryParams(`delete from file_link where num = $1`, num);
}
