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

	JSONValue pohodFilters;
	pohodFilters["sections"] = jv([
		[	"title": jv("По годам"),
			"items": jv([
				[	"text": jv("2018"),
					"fields": jv([
						"begin_date_range_head__year": 2018,
						"end_date_range_tail__year": 2018
					])
				],
				[	"text": jv("2017"),
					"fields": jv([
						"begin_date_range_head__year": 2017,
						"end_date_range_tail__year": 2017
					])
				],
				[	"text": jv("2016"),
					"fields": jv([
						"begin_date_range_head__year": 2016,
						"end_date_range_tail__year": 2016
					])
				],
				[	"text": jv("2015"),
					"fields": jv([
						"begin_date_range_head__year": 2015,
						"end_date_range_tail__year": 2015
					])
				],
				[	"text": jv("2014"),
					"fields": jv([
						"begin_date_range_head__year": 2014,
						"end_date_range_tail__year": 2014
					])
				],
				[	"text": jv("Последние 5 лет"),
					"fields": jv([
						"begin_date_range_head__year": 2014,
						"end_date_range_tail__year": 2018
					])
				]
			])
		],
		[	"title": jv("По видам туризма"),
			"items": jv([
				[ "text": jv("Водный"), "fields": jv([ "vid": 4]) ],
				[ "text": jv("Горный"), "fields": jv([ "vid": 3]) ],
				[ "text": jv("Пеший"), "fields": jv([ "vid": 1]) ],
				[ "text": jv("Велосипедный"), "fields": jv([ "vid": 5]) ],
				[ "text": jv("Лыжный"), "fields": jv([ "vid": 2]) ],
			])
		],
		[	"title": jv("По состоянию прохождения"),
			"items": jv([
				[ "text": jv("Планируется"), "fields": jv([ "prepar": 1]) ],
				[ "text": jv("Набор группы"), "fields": jv([ "prepar": 2]) ],
				[ "text": jv("Набор группы завершён"), "fields": jv([ "prepar": 3]) ],
				[ "text": jv("Подготовка"), "fields": jv([ "prepar": 4]) ],
				[ "text": jv("На маршруте"), "fields": jv([ "prepar": 5]) ],
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
	Service.JSON_RPCRouter.join!(getFavoritePohodFilters)(`pohod.favoriteFilters`);
}