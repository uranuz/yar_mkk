module mkk_site.main_service.document_edit;

import mkk_site.main_service.devkit;
import mkk_site.data_model.document;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editDocument)(`document.edit`);
	MainService.JSON_RPCRouter.join!(deleteDocument)(`document.delete`);
}

auto editDocument(HTTPContext ctx, DocumentDataToWrite record)
{
	import webtank.net.utils: PGEscapeStr;
	import std.conv: text, to;
	
	bool isAuthorized = ctx.user.isAuthenticated
		&& (ctx.user.isInRole("admin") || ctx.user.isInRole("moder"));
	if( !isAuthorized ) {
		throw new Exception(`Недостаточно прав для редактирования ссылки на документ!!!`);
	}
	
	string[] fieldNames;
	string[] fieldValues;

	if( !record.name.isUndef ) {
		fieldNames ~= `"name"`;
		fieldValues ~= record.name.isSet? `'` ~ PGEscapeStr(record.name) ~ `'`: `null`;
	}
	if( !record.link.isUndef ) {
		fieldNames ~= `"link"`;
		fieldValues ~= record.link.isSet? `'` ~ PGEscapeStr(record.link) ~ `'`: `null`;
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
	bool isAuthorized = ctx.user.isAuthenticated
		&& (ctx.user.isInRole("admin") || ctx.user.isInRole("moder"));
	if( !isAuthorized ) {
		throw new Exception(`Недостаточно прав для удаления ссылки на документ!!!`);
	}

	getCommonDB().query(`delete from file_link where num = ` ~ num.text);
}