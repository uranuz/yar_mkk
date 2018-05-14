module mkk_site.view_service.pohod_list;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;
import mkk_site.data_model.pohod_list;

shared static this() {
	ViewService.pageRouter.join!(renderPohodList)("/dyn/pohod/list");
	ViewService.pageRouter.join!(renderPartyInfo)("/dyn/pohod/partyInfo");
	ViewService.pageRouter.join!(renderExtraFileLinks)("/dyn/pohod/extraFileLinks");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

@IvyModuleAttr(`mkk.PohodList`)
TDataNode renderPohodList(HTTPContext ctx)
{
	import std.json: JSONValue, JSON_TYPE;
	import std.conv: to, ConvException;
	import std.exception: ifThrown;

	auto req = ctx.request;
	auto bodyForm = ctx.request.bodyForm;
	bool isForPrint = req.bodyForm.get("isForPrint", null) == "on";

	// Далее идёт вытаскивание данных фильтрации из формы и создание JSON со структурой фильтра
	PohodFilter pohodFilter;
	pohodFilter.init();
	formDataToStruct(bodyForm, pohodFilter);
	Navigation nav;
	formDataToStruct(bodyForm, nav);
	JSONValue filter = pohodFilter.toStdJSON(); // JSON с фильтрами по походам

	if( isForPrint ) {
		nav.pageSize = 10000;
	}

	TDataNode callResult = ctx.mainServiceCall("pohod.list", [
		"filter": filter,
		"nav": nav.toStdJSON()
	]);
	return TDataNode([
		"pohodList": callResult["rs"],
		"pohodNav": callResult["nav"],
		// Возвращаем поля фильтрации назад пользователю
		"filter": filter.toIvyJSON(),
		"pohodEnums": ctx.mainServiceCall("pohod.enumTypes"),
		"isForPrint": TDataNode(isForPrint)
	]);
}

@IvyModuleAttr(`mkk.PohodList.PartyInfo`)
TDataNode renderPartyInfo(HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.conv: to;
	size_t pohodNum = ctx.request.queryForm.get("key", "0").to!size_t;
	return ctx.mainServiceCall("pohod.partyInfo", ["num": pohodNum]);
}

@IvyModuleAttr(`mkk.PohodEdit.ExtraFileLinksEdit.LinkItems`)
TDataNode renderExtraFileLinks(HTTPContext ctx)
{
	import std.json: JSONValue, JSON_TYPE, parseJSON;
	import std.conv: to;
	import std.base64: Base64;

	TDataNode dataDict;
	if( "key" in ctx.request.queryForm ) {
		// Если есть ключ похода, то берем ссылки из похода
		size_t pohodNum = ctx.request.queryForm.get("key", "0").to!size_t;
		dataDict["linkList"] = ctx.mainServiceCall("pohod.extraFileLinks", ["num": pohodNum]);
	} else {
		// Иначе отрисуем список ссылок, который нам передали
		string rawExtraFileLinks = ctx.request.queryForm.get("extraFileLinks", null);
		string decodedExtraFileLinks = cast(string) Base64.decode(rawExtraFileLinks);
		JSONValue extraFileLinks = parseJSON(decodedExtraFileLinks);
		if( extraFileLinks.type != JSON_TYPE.ARRAY && extraFileLinks.type != JSON_TYPE.NULL  ) {
			throw new Exception(`Некорректный формат списка ссылок на доп. материалы`);
		}

		TDataNode[] linkList;
		if( extraFileLinks.type == JSON_TYPE.ARRAY ) {
			linkList.length = extraFileLinks.array.length;
			foreach( size_t i, ref JSONValue entry; extraFileLinks ) {
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
	dataDict["instanceName"] = ctx.request.queryForm.get("instanceName", null);

	return dataDict;
}