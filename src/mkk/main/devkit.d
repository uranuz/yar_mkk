/// Комплект модулей для разработки страниц сайта.
/// Импортирует основные модули, которые могут быть полезны для созданиия страниц сайта
module mkk.main.devkit;

// Импортируем модули библиотеки
public import
	webtank.common.conv,
	webtank.common.optional,
	webtank.common.optional_date,
	webtank.datctrl.iface.data_field,
	webtank.datctrl.iface.record,
	webtank.datctrl.iface.record_set,
	webtank.datctrl.enum_format,
	webtank.datctrl.enum_,
	webtank.datctrl.record_format,
	webtank.datctrl.cursor_record,
	webtank.datctrl.detatched_record,
	webtank.datctrl.record_set,
	webtank.datctrl.typed_record,
	webtank.datctrl.typed_record_set,
	webtank.datctrl.navigation,
	webtank.db,
	webtank.db.datctrl,
	webtank.db.utils,
	webtank.db.write_utils,
	webtank.net.http.context,
	webtank.net.http.consts,
	webtank.net.http.headers.consts,
	webtank.net.http.handler,
	webtank.net.utils,
	webtank.net.uri,
	webtank.security.right.common;

public import webtank.db.postgresql.serialize: toPGString;

//Импорт модулей сайта
public import
	mkk.main.service,
	mkk.common.utils,
	mkk.backend.database;

// Очень частые импорты
public import std.typecons: tuple, Tuple;
public import std.exception: enforce;
public import std.range: empty, front;