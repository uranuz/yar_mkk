module mkk_site.history.client;

import webtank.net.std_json_rpc_client;
import webtank.net.http.context: HTTPContext;
import webtank.common.optional: Optional;

import mkk_site.history.common;
import mkk_site.common.service;
import std.uuid;
import std.json: JSONValue, JSON_TYPE;
import webtank.common.std_json.to: toStdJSON;

UUID sendActionToHistory(HTTPContext ctx, string description, Optional!size_t userNum = Optional!size_t())
{
	import std.datetime: Clock, UTC, DateTime;
	import std.conv: to;

	UUID namespaceUUID = sha1UUID(`somenamespace`);
	UUID newActionUUID = sha1UUID(randomUUID().toString(), namespaceUUID);
	UUID parentUUID;
	if( userNum.isNull ) {
		userNum = ctx.user.data.get(`userNum`, `0`).to!size_t;
	}

	HistoryActionData data = {
		uuid: newActionUUID.toString(),
		parentUUID: parentUUID.toString(),
		description: description,
		userNum: userNum,
		time_stamp: cast(DateTime) Clock.currTime(UTC())
	};

	Service.endpoint(`yarMKKHistory`).remoteCall!(JSONValue)(
		`history.writeAction`, ctx, JSONValue(["data": data.toStdJSON()]));
	return newActionUUID;
}

void sendChangesToHistory(HTTPContext ctx, HistoryRecordData recordData)
{
	import std.exception: enforceEx;
	import std.conv: to;
	enforceEx!Exception(!recordData.recordNum.isNull, `Record num must be specified!`);
	enforceEx!Exception(recordData.tableName.length, `Table name be specified!`);

	// Номер пользователя берется из контекста, если не задан явно
	if( recordData.userNum.isNull ) {
		recordData.userNum = ctx.user.data.get(`userNum`, `0`).to!size_t;
	}

	Service.endpoint(`yarMKKHistory`).remoteCall!(JSONValue)(
		`history.writeData`, ctx, JSONValue(["data": recordData.toStdJSON()]));
}

// Записать действие в историю и сохранить изменения
void sendToHistory(HTTPContext ctx, string description, HistoryRecordData recordData)
{
	recordData.actionUUID = sendActionToHistory(ctx, description).toString();
	sendChangesToHistory(ctx, recordData);
}