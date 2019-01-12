module mkk_site.main_service.document_edit;

import mkk_site.main_service.devkit;
import mkk_site.data_model.document;
import webtank.security.right.common: GetSymbolAccessObject;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editDocument)(`document.edit`);
	MainService.JSON_RPCRouter.join!(deleteDocument)(`document.delete`);

	MainService.pageRouter.joinWebFormAPI!(renderEditDocument)("/api/document/edit");
	MainService.pageRouter.joinWebFormAPI!(writeDocument)("/api/document/edit/results");
}

auto editDocument(HTTPContext ctx, DocumentDataToWrite record)
{
	import webtank.net.utils: PGEscapeStr;
	import std.conv: text, to;
	import std.meta: AliasSeq;
	import std.traits: isSomeString, getUDAs;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`document.item`, `edit`), `Недостаточно прав для редактирования ссылки на документ!`);


	string[] fieldNames;
	string[] fieldValues;
	foreach( fieldName; AliasSeq!(__traits(allMembers, DocumentDataToWrite)) )
	{
		alias FieldType = typeof(__traits(getMember, record, fieldName));
		static if( isOptional!FieldType && OptionalIsUndefable!FieldType ) {
			auto field = __traits(getMember, record, fieldName);
			if( field.isUndef )
				continue; // Поля, которые undef с нашей т.зрения не изменились

			string accessObj = GetSymbolAccessObject!(DocumentDataToWrite, fieldName)();
			enforce(ctx.rights.hasRight(accessObj, `edit`), `Недостаточно прав для редактирования поля документа: ` ~ fieldName);

			enum string dbFieldName = getUDAs!(__traits(getMember, record, fieldName), DBName)[0].dbName;
			fieldNames ~= `"` ~ dbFieldName ~ `"`;
			static if( isSomeString!( OptionalValueType!FieldType ) ) {
				fieldValues ~= ( (field.isSet && field.length > 0)? "'" ~ PGEscapeStr(field.value) ~ "'": "NULL" );
			} else {
				static assert(false, `Unprocessed Undefable field: ` ~ fieldName);
			}
		}
	}

	if( fieldNames.length > 0 )
	{
		MainService.loger.info("Формирование и выполнение запроса к БД", "Изменение ссылки на документ");
		string queryStr;

		import std.array: join;
		if( record.num.isSet )	{
			queryStr = "update file_link set( " ~ fieldNames.join(", ") ~ " ) = ( " ~ fieldValues.join(", ") ~ " ) where num = '" ~ record.num.text ~ "' returning num";
		} else {
			queryStr = "insert into file_link ( " ~ fieldNames.join(", ") ~ " ) values( " ~ fieldValues.join(", ") ~ " ) returning num";
		}

		auto writeQueryRes = getCommonDB().query(queryStr); // Собственно запрос на запись данных в БД
		if( writeQueryRes && writeQueryRes.recordCount == 1 ) {
			return writeQueryRes.get(0, 0, null).to!size_t;
		}
	}

	MainService.loger.info("Выполнение запроса к БД завершено", "Изменение ссылки на документ");
	return record.num;
}

/++ Простой, но опасный метод, который удаляет сылку на документ по ключу. +/
void deleteDocument(HTTPContext ctx, size_t num)
{
	import std.conv: text;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`document.item`, `delete`), `Недостаточно прав для удаления документа!`);

	getCommonDB().query(`delete from file_link where num = ` ~ num.text);
}


import mkk_site.main_service.document_list: getDocumentList;

import std.json: JSONValue;
JSONValue renderEditDocument(HTTPContext ctx, Optional!size_t num)
{
	DocumentListFilter filter;
	Navigation nav;
	if( num.isSet ) {
		filter.nums = [num.value];
	}
	auto callResult = getDocumentList(ctx, filter, nav);

	return JSONValue([
		"document": (
			callResult.documentList && callResult.documentList.length?
			callResult.documentList[0].toStdJSON():
			JSONValue(null))
	]);
}

JSONValue writeDocument(HTTPContext ctx, DocumentDataToWrite record, string instanceName)
{
	JSONValue result = [
		"errorMsg": JSONValue(null),
		"docNum": record.num.isSet? JSONValue(record.num.value): JSONValue(null),
		"isUpdate": JSONValue(record.num.isSet),
		"instanceName": JSONValue(instanceName)
	];
	try {
		result["docNum"] = editDocument(ctx, record);
	} catch(Exception ex) {
		result["errorMsg"] = ex.msg; // Передаём сообщение об ошибке в шаблон
	}

	return result;
}