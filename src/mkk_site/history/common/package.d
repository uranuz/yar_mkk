module mkk_site.history.common;

import std.datetime: DateTime;
import std.json: JSONValue;
import webtank.common.optional: Optional;

enum HistoryRecordKind: ubyte
{
	Update, // Обновление записи (передана вся запись)
	Insert, // Вставка новой записи
	UpdatePartial, // Обновление записи (переданы изменения)
	Delete // Удаление записи
}

struct HistoryRecordData
{
	string tableName;
	Optional!size_t recordNum;
	JSONValue data;
	Optional!size_t userNum;
	string actionUUID;
	HistoryRecordKind recordKind;
}

struct HistoryActionData
{
	string uuid;
	string parentUUID;
	string description;
	Optional!size_t userNum;
	DateTime time_stamp;
}