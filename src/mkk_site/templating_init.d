module mkk_site.templating_init;
// Этот модуль предназначен для импортирования только из mkk_site.templating
// Иначе это может привести к проблеме циклических зависимостей конструкторов

import
	webtank.templating.plain_templater,
	webtank.ui.templating;

import mkk_site.site_data;
import mkk_site.templating;

import std.json: JSONValue, JSON_TYPE;
static immutable JSONValue pohodFiltersJSON;
static immutable string[] pohodFilterFields;

shared static this()
{
	templateCache = new PlainTemplateCache!(withTemplateCache)();
	webtank.ui.templating.setTemplatesDir( webtankResDir ~ "templates" );

	alias jv = JSONValue;

	pohodFiltersJSON = jv([
		[	"title": jv("По годам"),
			"items": jv([
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
				[	"text": jv("2013"),
					"fields": jv([
						"begin_date_range_head__year": 2013,
						"end_date_range_tail__year": 2013
					])
				],
				[	"text": jv("2012"),
					"fields": jv([
						"begin_date_range_head__year": 2012,
						"end_date_range_tail__year": 2012
					])
				],
				[	"text": jv("Последние 5 лет"),
					"fields": jv([
						"begin_date_range_head__year": 2012,
						"end_date_range_tail__year": 2016
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

	foreach( ref section; pohodFiltersJSON.array )
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

	import std.exception: assumeUnique;
	pohodFilterFields = assumeUnique( filterFields );
} 
