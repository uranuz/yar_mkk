module mkk_site.main_service.pohod_filters;

import mkk_site.main_service.service;

import std.json: JSONValue, JSON_TYPE;
static immutable JSONValue pohodFiltersJSON;

/// Публичный метод сервиса для получения списка избранных фильтров по походам.
/// Данные используются для построения бокового меню сайта
JSONValue getFavoritePohodFilters() {
	return pohodFiltersJSON;
}

shared static this()
{
	alias jv = JSONValue;

	import std.datetime;
	import std.conv: text;

	static immutable size_t yearCount = 5;
	SysTime dt = Clock.currTime();
	JSONValue[] yearItems;

	foreach( i; 0..yearCount )
	{
		auto year = dt.year - i;
		yearItems ~= jv([
			"text": jv(year.text),
			"fields": jv([
				"dates__beginRangeHead__year": year,
				"dates__endRangeTail__year": year
			])
		]);
	}
	yearItems ~= jv([
		"text": jv("Последние " ~ yearCount.text ~ " лет"),
		"fields": jv([
			"dates__beginRangeHead__year": dt.year - yearCount + 1,
			"dates__endRangeTail__year": dt.year
		])
	]);

	JSONValue pohodFilters;
	pohodFilters["sections"] = jv([
		[	"title": jv("По годам"),
			"items": jv(yearItems)
		],
		[	"title": jv("По видам туризма"),
			"items": jv([
				[ "text": jv("Водный"), "fields": jv([ "tourismKind": 4]) ],
				[ "text": jv("Горный"), "fields": jv([ "tourismKind": 3]) ],
				[ "text": jv("Пеший"), "fields": jv([ "tourismKind": 1]) ],
				[ "text": jv("Велосипедный"), "fields": jv([ "tourismKind": 5]) ],
				[ "text": jv("Лыжный"), "fields": jv([ "tourismKind": 2]) ],
			])
		],
		[	"title": jv("По состоянию прохождения"),
			"items": jv([
				[ "text": jv("Планируется"), "fields": jv([ "progress": 1]) ],
				[ "text": jv("Набор группы"), "fields": jv([ "progress": 2]) ],
				[ "text": jv("Набор группы завершён"), "fields": jv([ "progress": 3]) ],
				[ "text": jv("Подготовка"), "fields": jv([ "progress": 4]) ],
				[ "text": jv("На маршруте"), "fields": jv([ "progress": 5]) ],
			])
		]
	]);


	string[] filterFields;
	import std.algorithm: canFind;

	foreach( ref section; pohodFilters["sections"].array )
	{
		if( section.type != JSON_TYPE.OBJECT )
			continue;

		foreach( ref item; section["items"].array )
		{
			if( item.type != JSON_TYPE.OBJECT )
				continue;

			foreach( key, val; item["fields"].object )
			{
				if( !filterFields.canFind( key ) )
					filterFields ~= key;
			}
		}
	}

	pohodFilters["allFields"] = JSONValue(filterFields);
	pohodFiltersJSON = pohodFilters;

	// Регистрируем метод в сервисе
	MainService.JSON_RPCRouter.join!(getFavoritePohodFilters)(`pohod.favoriteFilters`);
}