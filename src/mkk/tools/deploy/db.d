module mkk.tools.deploy.db;

import std.getopt: getopt;
import std.stdio: writeln;
import std.exception: enforce;

import mkk.tools.auth_db: getAuthDB, getCommonDB;
import webtank.db.datctrl: getScalar;

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
	writeln(`Версия конвертера v0.5.1`);
	// Нужна хотя бы тупая, минимальная проверка на сконвертированность
	bool alreadyConverted = getCommonDB().query(`
select not exists(
	select column_name
	from information_schema.columns
	where
		table_name = 'pohod'
		and
		column_name = 'unit_neim'
)
	`).getScalar!bool();
	enforce(!alreadyConverted, `База данных уже сконвертирована!`);

	writeln(`Добавление таблицы pohod_party`);
	getCommonDB().query(`
CREATE SEQUENCE public.pohod_party_num_seq;

CREATE TABLE public.pohod_party
(
	num integer NOT NULL DEFAULT nextval('pohod_party_num_seq'::regclass),
	pohod_num integer,
	tourist_num integer,
	CONSTRAINT pohod_party_num PRIMARY KEY (num)
)
WITH (
	OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.pohod_party
	OWNER to postgres;
COMMENT ON TABLE public.pohod_party
	IS 'Группа туристов похода';

COMMENT ON COLUMN public.pohod_party.num
	IS 'Первичный ключ';

COMMENT ON COLUMN public.pohod_party.pohod_num
	IS 'Идентификатор похода, к которому относятся группа и, соответственно, участники';

COMMENT ON COLUMN public.pohod_party.tourist_num
	IS 'Идентификатор туриста';

ALTER SEQUENCE pohod_party_num_seq OWNED BY public.pohod_party.num;
	`);


	writeln(`Перемещение данных из pohod.unit_neim в pohod_party`);
	getCommonDB.query(`
with party(pohod_num, tourist_num) as(
	select
		ph.num, unnest(ph.unit_neim)
	from pohod ph
)
insert into pohod_party(pohod_num, tourist_num)
select * from party
	`);

	writeln(`Удаление колонки pohod.unit_neim`);
	getCommonDB().query(`
ALTER TABLE public.pohod DROP COLUMN unit_neim
	`);
}