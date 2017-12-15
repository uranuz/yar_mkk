module mkk_site.main_service.document_list;

import mkk_site.main_service.devkit;
import mkk_site.data_model.enums;
import mkk_site.data_model.document;

import webtank.common.std_json.to: toStdJSON;

shared static this()
{
	Service.JSON_RPCRouter.join!(getDocumentList)(`document.list`);
}

import std.json: JSONValue;

static immutable documentRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "name",
	string, "link"
)();

JSONValue getDocumentList(HTTPContext ctx, DocumentListFilter filter, Navigation nav)
{
	import webtank.datctrl.record_set;
	import std.conv: to, text;
	import std.string: join;

	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10); // Задаем параметры по умолчанию

	if( filter.nums.isNull )
	{
		// Особый случай/костыль - список идентфикаторов передан, но он пуст (null или length == 0)
		// при этом возвращаем только одну пустую запись по формату документа без похода в базу.
		// Остальные фильтры в этом случае уже по боку.
		// Эта подпорка требуется для создания нового документа.
		// Но если фильтра нет вовсе filter.nums.isUndef == true, то он просто не работает.
		auto rsWithOneItem = makeMemoryRecordSet(documentRecFormat);
		rsWithOneItem.addItems(1); // Добавляем одну пустую запись для редактирования
		nav.normalize(1);
		return JSONValue([
			"rs": rsWithOneItem.toStdJSON(),
			"nav": nav.toStdJSON()
		]);
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

	return JSONValue([
		"rs": getCommonDB().query(
			`select num, name, link from file_link` ~ filterQuery
			~ ` order by name offset ` ~ nav.offset.text ~ ` limit ` ~ nav.pageSize.text
		).getRecordSet(documentRecFormat).toStdJSON(),
		"nav": nav.toStdJSON()
	]);
}



