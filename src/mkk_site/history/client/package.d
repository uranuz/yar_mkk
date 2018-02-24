module mkk_site.history_service.client;

import webtank.net.std_json_rpc;

import mkk_site.history.service.common;

UUID sendActionToHistory(string description, HTTPContext ctx)
{
	import std.uuid;
	import std.datetime: Clock, UTC;
	UUID namespaceUUID = sha1UUID(`somenamespace`);
	UUID newActionUUID = sha1UUID(randomUUID().toString(), namespaceUUID);
	UUID parentUUID;
	string userNum;

	HistoryActionData data = {
		
	};

	remoteCall!(JSONValue)(
		`http://localhost/history-rpc`,
		context, 
		JSONValue([
			"uuid": newActionUUID.toString(),
			"parentUUID": parentUUID.toString(),
			"description": description,
			"userNum": userNum,
			"time_stamp": Clock.currTime(UTC()).toISOExtString()
		])
	);

}

size_t sendChangesToHistory()
{

}