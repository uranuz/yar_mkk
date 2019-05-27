module mkk_site.main_service.db_utils;

import webtank.db.database: IDatabase;
import webtank.common.optional: Optional;

Optional!size_t insertOrUpdateTableByNum(
	IDatabase db,
	string table,
	string[] fieldNames,
	string[] fieldValues,
	Optional!size_t num = Optional!size_t(),
	string[] safeFieldNames = null,
	string[] safeFieldValues = null
) {
	import std.exception: enforce;
	import std.range: empty, iota, chain;
	import std.algorithm: map;
	import std.array: join;
	import std.conv: text, to;

	import webtank.db.database: IDBQueryResult;

	enforce(fieldNames.length == fieldValues.length, `Field names and values count must be equal`);
	enforce(safeFieldNames.length == safeFieldValues.length, `Safe field names and values count must be equal`);
	if( fieldNames.empty && safeFieldNames.empty ) {
		return Optional!size_t();
	}
	string fieldNamesJoin = chain(fieldNames, safeFieldNames).map!( (it) => `"` ~ it ~ `"` ).join(", ");
	string placeholders = iota(1, fieldNames.length + 1).map!( (it) => `$` ~ it.text )().join(`, `);
	string placeOrSafeValues = [placeholders, safeFieldValues.join(`, `)].join(`, `);

	string queryStr;
	if( num.isSet ) {
		queryStr = `update "` ~ table ~ `" set(` ~ fieldNamesJoin ~ `) = (` ~ placeOrSafeValues ~ `) where num = ` ~ num.text ~ ` returning num`;
	} else {
		queryStr = `insert into "` ~ table ~ `" (` ~ fieldNamesJoin ~ `) values(` ~ placeOrSafeValues ~ `) returning num`;
	}

	IDBQueryResult queryRes = db.queryParamsArray(queryStr, fieldValues);
	return Optional!size_t(queryRes.get(0, 0, "0").to!size_t);
}