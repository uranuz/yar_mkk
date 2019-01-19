module mkk_site.main_service.document.edit;

import mkk_site.main_service.devkit;
import mkk_site.data_model.document;
import webtank.security.right.common: GetSymbolAccessObject;

import std.typecons: Tuple;

shared static this()
{
	MainService.JSON_RPCRouter.join!(writeDocument)(`document.edit`);
	MainService.JSON_RPCRouter.join!(deleteDocument)(`document.delete`);

	MainService.pageRouter.joinWebFormAPI!(writeDocument)("/api/document/edit/results");
}

Tuple!(Optional!size_t, "documentNum")
writeDocument(HTTPContext ctx, DocumentDataToWrite record)
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

	auto res = typeof(return)(record.num);
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
			res.documentNum = writeQueryRes.get(0, 0, null).to!size_t;
		}
	}

	MainService.loger.info("Выполнение запроса к БД завершено", "Изменение ссылки на документ");
	return res;
}

/++ Простой, но опасный метод, который удаляет сылку на документ по ключу. +/
void deleteDocument(HTTPContext ctx, size_t num)
{
	import std.conv: text;
	import std.exception: enforce;
	enforce(ctx.rights.hasRight(`document.item`, `delete`), `Недостаточно прав для удаления документа!`);

	getCommonDB().query(`delete from file_link where num = ` ~ num.text);
}
