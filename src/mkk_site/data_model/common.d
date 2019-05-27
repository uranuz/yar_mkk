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

import webtank.net.http.context: HTTPContext;
private void _checkItemRights(DataStruct, string fieldName)(HTTPContext ctx, string accessKind)
{
	import mkk_site.security.common.exception: SecurityException;
	import webtank.security.right.common: GetSymbolAccessObject;
	import std.exception: enforce;
	string accessObj = GetSymbolAccessObject!(DataStruct, fieldName)();
	enforce!SecurityException(
		ctx.rights.hasRight(accessObj, accessKind),
		`Недостаточно прав для редактирования поля: ` ~ fieldName);
}

void checkStructEditRights(DataStruct)(auto ref DataStruct record, HTTPContext ctx, string accessKind = `edit`)
{
	import mkk_site.security.common.exception: SecurityException;
	import webtank.security.right.common: RightObjAttr;
	import std.meta: AliasSeq;
	import std.traits: getUDAs;
	import webtank.common.optional: isUndefable;
	foreach( fieldName; AliasSeq!(__traits(allMembers, DataStruct)) )
	{
		alias FieldType = typeof(__traits(getMember, record, fieldName));
		alias RightObjAttrs = getUDAs!(__traits(getMember, record, fieldName), RightObjAttr);
		static if( isUndefable!FieldType )
		{
			auto field = __traits(getMember, record, fieldName);
			if( field.isUndef )
				continue; // Если поле не изменилось, то права на него не проверяем
			_checkItemRights!(DataStruct, fieldName)(ctx, accessKind);
		} else static if( RightObjAttrs.length > 0 ) {
			_checkItemRights!(DataStruct, fieldName)(ctx, accessKind);
		}
	}
}

/++
	Шаблон, который генерирует код, выполняющий обход полей типа Undefable для переменной c именем recordVar.
	Поля со значением isUndef = true игнорируются при этом.
	Для каждого из указанных полей, выполняется код, переданный в параметре payload
	`Миксин` определяет ряд символов для использования:
		fieldName - имя поля
		FieldSymbol - `символ` поля. Символ - это не тип и не значение
		FieldType - тип поля
		dbFieldName - имя поля в базе данных (если задано через аттрибут DBName)
		field - значение поля
+/
template WalkFields(string recordVar, string payload)
{
	import std.format: format;
	enum string WalkFields = (q{
		import std.meta: AliasSeq;
		import std.traits: getUDAs;
		import webtank.common.optional: isUndefable;
		
		foreach( fieldName; AliasSeq!(__traits(allMembers, typeof(%1$s))) )
		{
			alias FieldSymbol = __traits(getMember, %1$s, fieldName);
			alias FieldType = typeof(FieldSymbol);
			static if( isUndefable!FieldType )
			{
				alias DBNameAttrs = getUDAs!(FieldSymbol, DBName);
				static assert(
					DBNameAttrs.length < 2,
					`Expected one or zero DBName attrs on struct field`);
				static if( DBNameAttrs.length ) {
					enum string dbFieldName = DBNameAttrs[0].dbName;
				} else {
					enum string dbFieldName = null;
				}

				auto field = __traits(getMember, record, fieldName);
				if( field.isUndef )
					continue;

				%2$s
			}
		}
	}).format(recordVar, payload);
}