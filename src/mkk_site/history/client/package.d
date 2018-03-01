module mkk_site.history.client;

import webtank.net.std_json_rpc_client;
import webtank.net.http.context: HTTPContext;
import webtank.common.optional: Optional;

import mkk_site.history.common;
import mkk_site.common.service;
import std.uuid;
import std.json: JSONValue, JSON_TYPE;
import webtank.common.std_json.to: toStdJSON;

/// Добавить запись о совершаемом действии в историю
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

/// Сохранить изменения в историю (для одной записи)
void sendChangesToHistory(HTTPContext ctx, HistoryRecordData data) {
	sendChangesToHistory(ctx, [data]);
}

/// Сохранить изменения в историю (несколько записей)
void sendChangesToHistory(HTTPContext ctx, HistoryRecordData[] data)
{
	import std.exception: enforceEx;
	import std.conv: to;
	size_t userNum = ctx.user.data.get(`userNum`, `0`).to!size_t;
	foreach( ref item; data )
	{
		enforceEx!Exception(!item.recordNum.isNull, `Record num must be specified!`);
		enforceEx!Exception(item.tableName.length, `Table name be specified!`);

		// Номер пользователя берется из контекста, если не задан явно
		if( item.userNum.isNull ) {
			item.userNum = userNum;
		}
	}

	Service.endpoint(`yarMKKHistory`).remoteCall!(JSONValue)(
		`history.writeData`, ctx, JSONValue(["data": data.toStdJSON()]));
}

// Записать действие в историю и сохранить изменения
void sendToHistory(HTTPContext ctx, string description, HistoryRecordData data) {
	sendToHistory(ctx, description, [data]);
}

// Записать действие в историю и сохранить изменения
void sendToHistory(HTTPContext ctx, string description, HistoryRecordData[] data)
{
	auto actionUUID = sendActionToHistory(ctx, description).toString();
	foreach( ref item; data ) {
		item.actionUUID = actionUUID;
	}
	sendChangesToHistory(ctx, data);
}