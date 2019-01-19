module mkk_site.main_service.document.list;

import mkk_site.main_service.devkit;
import mkk_site.data_model.document;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getDocumentList)(`document.list`);

	MainService.pageRouter.joinWebFormAPI!(getDocumentList)("/api/document/list");
}

static immutable documentRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "name",
	string, "link"
)();

import std.typecons: Tuple;

Tuple!(
	IBaseRecordSet, "documentList",
	Navigation, "nav",
	DocumentListFilter, "filter"
)
getDocumentList(HTTPContext ctx, DocumentListFilter filter, Navigation nav)
{
	import webtank.datctrl.record_set;
	import std.conv: to, text;
	import std.string: join;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	if( filter.nums.isSet && filter.nums.length == 0 )
	{
		// Особый случай/костыль - список идентфикаторов передан, но он пуст (length == 0)
		// при этом возвращаем только одну пустую запись по формату документа без похода в базу.
		// Остальные фильтры в этом случае уже не важны.
		// Эта подпорка требуется для создания нового документа.
		// Но если фильтра нет вовсе filter.nums.isNull == true, то он просто не работает.
		auto rsWithOneItem = makeMemoryRecordSet(documentRecFormat);
		rsWithOneItem.addItems(1); // Добавляем одну пустую запись для редактирования
		nav.normalize(1);
		return typeof(return)(rsWithOneItem, nav, filter);
	}
	
	string[] filters;
	if( filter.name.length ) {
		filters ~= `name ilike '%' || '` ~ PGEscapeStr(filter.name) ~ `' || '%'`;
	}
	if( filter.nums.isSet ) {
		filters ~= `num in(` ~ filter.nums.value.to!(string[]).join(",") ~ `)`;
	}

	string filterQuery = filters.length? ` where (` ~ filters.join(`) and (`) ~ `) `: null;
	nav.normalize(
		getCommonDB().query(
			`select count(1) from file_link` ~ filterQuery
		).get(0, 0, "0").to!size_t
	);

	return typeof(return)(
		getCommonDB().query(
			`select num, name, link from file_link` ~ filterQuery
			~ ` order by name offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text
		).getRecordSet(documentRecFormat),
		nav,
		filter
	);
}
