module mkk.tools.deploy.db;

import std.getopt: getopt;
import std.stdio: writeln;
import std.exception: enforce;

import mkk.backend.database: getAuthDB, getCommonDB, getHistoryDB;
import webtank.db.datctrl: getScalar;
import webtank.db.transaction: makeTransaction;
import webtank.db: queryParams;

void main(string[] args)
{
	bool isHelp = false;

	getopt(args,
		`help|h`, &isHelp
	);

	if( isHelp ) {
		writeln(
`Утилита конвертации базы данных МКК. Содержит набор SQL-скриптов для приведения базы из старого вида к новому
Опции:
--help|h Эта справка
`);
		return;
	}

	convertDB();
}

void convertDB()
{
	writeln(`Версия конвертера v0.5.2`);
	renameTouristPohodFields();
	dropEnumTypes();
}

static immutable string[string] touristNewFields;
static immutable string[string] pohodNewFields;

shared static this()
{
	touristNewFields = [
		`exp`: `experience`,
		`razr`: `sport_category`,
		`sud`: `referee_category`
	];
	pohodNewFields = [
		`kod_mkk`: `mkk_code`,
		`nomer_knigi`: `book_num`,
		`region_pohod`: `pohod_region`,
		`region_group`: `party_region`,
		`marchrut`: `route`,
		`chef_grupp`: `chief_num`,
		`alt_chef`: `alt_chief_num`,
		`unit`: `party_size`,
		`chef_coment`: `chief_comment`,
		`MKK_coment`: `mkk_comment`,
		`vid`: `tourism_kind`,
		`ks`: `complexity`,
		`elem`: `complexity_elem`,
		`prepar`: `progress`,
		`stat`: `claim_state`
	];
}

void renameTouristPohodFields()
{
	renameFields(`tourist`, touristNewFields);
	renameFields(`pohod`, pohodNewFields);
}

void renameFields(string table, const(string[string]) newFields)
{
	auto comTrans = getCommonDB().makeTransaction();
	scope(success) comTrans.commit();
	scope(failure) comTrans.rollback();

	auto histTrans = getHistoryDB().makeTransaction();
	scope(success) histTrans.commit();
	scope(failure) histTrans.rollback();

	renameTableFields(table, newFields);
	renameHistoryFields(table, newFields);
}

void renameTableFields(string table, const(string[string]) newFields)
{
	import std.algorithm: map;
	import std.array: join;

	writeln(`Переименование колонок в таблице: ` ~ table);

	foreach( old_name, new_name; newFields )
	{
		bool alreadyConverted = getCommonDB().queryParams(`
		select exists(
			select column_name
			from information_schema.columns
			where
				table_name = $1::text
				and
				column_name = $2::text
		)`, table, new_name).getScalar!bool();

		enforce(!alreadyConverted, `Таблица туристов уже сконвертирована`);
		break; // Проверяем первую попавшуюся колонку
	}

	getCommonDB().query(
		newFields.byKeyValue.map!((it) =>
`ALTER TABLE "` ~ table ~ `"
RENAME COLUMN "` ~ it.key ~ `" TO "` ~ it.value ~ `";`
		).join("\n")
	);
}

void renameHistoryFields(string table, const(string[string]) newFields)
{
	import std.algorithm: map;
	import std.array: join;

	string histTable = `_hc__` ~ table;

	writeln(`Переименование полей в истории для таблицы: ` ~ table);

	// Переименуем поле с данными
	getHistoryDB().query(`
ALTER TABLE "` ~ histTable ~ `"
RENAME COLUMN "data" TO "old_data";
	`);

	getHistoryDB().query(`
	ALTER TABLE "` ~ histTable ~ `"
ADD COLUMN "data" jsonb;
	`);

	getHistoryDB().query(`
	update "` ~ histTable ~ `" as upd_hc
	set data = for_upd.data
	from (
		with field_map(old_name, new_name) as(
			values
			` ~ newFields.byKeyValue.map!(
					(it) => `('` ~ it.key ~ `', '` ~ it.value ~ `')`
				).join(",\n\t\t\t") ~ `
		)
		select
			p_old.num,
			jsonb_object_agg(
				(case
					when fm.new_name is not null
						then fm.new_name -- Колонка переименовывается
					else
						p_old."key" -- Не переименовывается
				end),
				p_old."value"
			) as data
		from(
			select
				num,
				(jsonb_each(inp.old_data)).*
			from "` ~ histTable ~ `" inp
			where
				inp.old_data is not null
				and
				inp.old_data != 'null'::jsonb
		) p_old(num, "key", "value")
		left join field_map fm
			on fm.old_name = p_old."key"
		group by p_old.num
	) as for_upd
	where
		upd_hc.num = for_upd.num
	`);
}

void dropEnumTypes()
{
	import std.string: join;
	import std.algorithm: map;

	writeln(`Удаление неиспользуемых перечислимых типов`);

	// Удаляем неиспользуемые типы из БД
	string[] enumTypes = [`element`, `ks`, `prava`, `prepare`, `razryad`, `status`, `syd`, `vid`];
	getCommonDB().query(enumTypes.map!( (en) => `DROP TYPE public.` ~ en ~ `;` ).join("\n"));
}