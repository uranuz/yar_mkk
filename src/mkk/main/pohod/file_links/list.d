module mkk.main.pohod.file_links.list;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getExtraFileLinks)(`pohod.extraFileLinks`);

	MainService.pageRouter.joinWebFormAPI!(renderExtraFileLinks)("/api/pohod/extra_file_links");
}

static immutable pohodFileLinkRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "name",
	string, "link"
)();

IBaseRecordSet getExtraFileLinks(Optional!size_t num)
{
	import std.conv: text;
	return getCommonDB().query(
		`select num, name, link as num from pohod_file_link where pohod_num = ` ~ (num.isSet? num.text: `null::integer`)
	).getRecordSet(pohodFileLinkRecFormat);
}

auto renderExtraFileLinks(Optional!size_t num, string extraFileLinks)
{
	import std.json: JSONValue, JSON_TYPE, parseJSON;
	import std.conv: to;
	import std.base64: Base64;
	import webtank.common.optional: Optional;

	JSONValue dataDict;
	if( num.isSet ) {
		// Если есть ключ похода, то берем ссылки из похода
		dataDict["linkList"] = getExtraFileLinks(num).toStdJSON();
	} else {
		// Иначе отрисуем список ссылок, который нам передали
		string decodedExtraFileLinks = cast(string) Base64.decode(extraFileLinks);
		JSONValue jExtraFileLinks = parseJSON(decodedExtraFileLinks);
		if( jExtraFileLinks.type != JSON_TYPE.ARRAY && jExtraFileLinks.type != JSON_TYPE.NULL  ) {
			throw new Exception(`Некорректный формат списка ссылок на доп. материалы`);
		}

		JSONValue[] linkList;
		if( jExtraFileLinks.type == JSON_TYPE.ARRAY ) {
			linkList.length = jExtraFileLinks.array.length;
			foreach( size_t i, ref JSONValue entry; jExtraFileLinks ) {
				if( entry.type != JSON_TYPE.ARRAY || entry.array.length < 2) {
					throw new Exception(`Некорректный формат элемента списка ссылок на доп. материалы`);
				}
				if( entry[0].type != JSON_TYPE.STRING && entry[0].type != JSON_TYPE.NULL ) {
					throw new Exception(`Некорректный формат описания ссылки на доп. материалы`);
				}
				if( entry[1].type != JSON_TYPE.STRING && entry[1].type != JSON_TYPE.NULL ) {
					throw new Exception(`Некорректный формат ссылки на доп. материалы`);
				}
				linkList[i] = [
					(entry[0].type == JSON_TYPE.STRING? entry[0].str : null),
					(entry[1].type == JSON_TYPE.STRING? entry[1].str : null)
				];
			}
		}
		dataDict["linkList"] = linkList;
	}

	return dataDict;
}