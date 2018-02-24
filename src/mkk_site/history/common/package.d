module mkk_site.history_service.common;

import std.datetime: DateTime;

struct HistoryActionData
{
	string uuid;
	string parentUUID;
	string description;
	size_t userNum;
	DateTime time_stamp;
}