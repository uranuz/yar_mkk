module mkk_site.data_model.common;

// Используется в качестве аттрибута для указания названия поля в базе данных
struct DBName
{
	string dbName;
}

import std.json: JSONValue;
public import webtank.common.std_json.to: FieldSerializer;
void maybeDBSerializeMethod(string name, T)(ref T dValue, ref JSONValue[string] jArray)
{
	import webtank.common.std_json.to: toStdJSON;
	static if( name != `dbSerializeMode` )
	{
		import std.traits: getUDAs;
		alias dbAttrs = getUDAs!( __traits(getMember, dValue, name), DBName );
		static if( dbAttrs.length == 0 ) {
			jArray[name] = toStdJSON( __traits(getMember, dValue, name) );
		} else static if( dbAttrs.length == 1 ) {
			string serializedName = dValue.dbSerializeMode? dbAttrs[0].dbName: name;
			jArray[serializedName] = toStdJSON( __traits(getMember, dValue, name) );
		} else static assert(false, `Expected 0 or 1 DBName attributes count!!!`);
	}
}

// Структура для навигации по выборке данных
struct Navigation
{
	import webtank.common.optional: Undefable;
	// Замечание: Обычно с "клиента" передается либо offset, либо currentPage, но не одновременно,
	// хотя не заперещаем явным образом передавать и то и другое.
	// При этом "сервер" может вернуть все эти поля в качестве доп. информации, чтобы не считать на "клиенте".
	// Входные поля носят "рекомендательный" характер для "сервера".
	// "Сервер" может игнорировать эти значения и подставить вместо них свои,
	// но при этом желательно, чтобы "сервер" вернул эти значения,
	// чтобы "клиент" мог узнать какую фактическую выборку он получил

	// Следующие поля являются как входными, так и выходными
	/++
	Сдвиг текущей страницы по числу записей.
	Отрицательное значение (если поддерживается) означает сдвиг от конца выборки
	+/
	Undefable!ptrdiff_t offset;

	/++ Число записей на странице +/
	Undefable!size_t pageSize;

	/++
	Номер текущей страницы.
	Отрицательное значение (если поддерживается) означает сдвиг от конца выборки в страницах
	+/
	Undefable!ptrdiff_t currentPage;


	// Эти поля являются только выходными. Могут отдаваться "сервером", если эта информация есть
	/++ Число записей в полной выборке данных (с учётом фильтра) +/
	Undefable!size_t recordCount;

	/++ Число страниц в полной выборке (с учётом фильтра) +/
	Undefable!size_t pageCount;

	void normalize(size_t recCount)
	{
		recordCount = recCount;
		if( offset.isSet && pageSize.isSet && recordCount < offset ) {
			// Устанавливаем offset на начало последней страницы, если offset выходит за число записей
			offset = (recordCount / pageSize) * pageSize;
		}
	}
}