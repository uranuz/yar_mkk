module mkk_site.history.common;

import std.datetime: DateTime;
import std.json: JSONValue;
import webtank.common.optional: Optional;

struct HistoryRecordData
{
	string tableName;
	Optional!size_t recordNum;
	JSONValue data;
	Optional!size_t userNum;
	string actionUUID;
	bool isSnapshot = false;
}

struct HistoryActionData
{
	string uuid;
	string parentUUID;
	string description;
	Optional!size_t userNum;
	DateTime time_stamp;
}