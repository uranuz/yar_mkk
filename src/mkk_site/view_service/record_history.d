module mkk_site.view_service.record_history;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

import mkk_site.common.service: Service;
import webtank.ivy.rpc_client;

shared static this() {
	ViewService.pageRouter.join!(renderRecordHistory)("/dyn/{object}/history");
}

import ivy;

import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.net.deserialize_web_form: formDataToStruct;
import webtank.common.std_json.to: toStdJSON;

import mkk_site.history.common;
import mkk_site.data_model.common: Navigation;

@IvyModuleAttr(`mkk.RecordHistory`)
TDataNode renderRecordHistory(HTTPContext ctx)
{
	import std.json: JSONValue, JSON_TYPE;
	import std.conv: to, ConvException;
	import std.exception: ifThrown, enforce;
	import std.algorithm: canFind;

	auto req = ctx.request;
	auto bodyForm = ctx.request.bodyForm;
	auto queryForm = ctx.request.queryForm;
	string method = ctx.request.requestURIMatch.params.get("object", null).to!string;
	enforce( ["pohod", "tourist"].canFind(method), `Объект истории не найден!` );

	// Далее идёт вытаскивание данных фильтрации из формы и создание JSON со структурой фильтра
	RecordHistoryFilter pohodFilter;

	enforce( queryForm["key"].length, `Невозможно отобразить историю. Номер записи не задан` );

	try {
		pohodFilter.recordNum = queryForm.get("key", null).to!size_t;
	} catch( ConvException e ) {
		throw new Exception(`Невозможно отобразить историю. Номер записи должен быть целым числом`);
	}

	Navigation nav;
	formDataToStruct(bodyForm, nav);

	TDataNode callResult = ctx.endpoint(`yarMKKHistory`).remoteCall!(TDataNode)("history." ~ method, [
		"filter": pohodFilter.toStdJSON(),
		"nav": nav.toStdJSON()
	]);

	return TDataNode([
		"history": callResult,
		"objectName": TDataNode("pohod" == method? "поход": "турист")
	]);
}