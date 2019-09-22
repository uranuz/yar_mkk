module mkk.tools.deploy.db;

import std.getopt: getopt;
import std.stdio: writeln;
import std.exception: enforce;

import mkk.tools.auth_db: getAuthDB;
import webtank.db.datctrl_joint: getScalar;

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
	writeln(`Версия конвертера v0.5`);
	// Нужна хотя бы тупая, минимальная проверка на сконвертированность
	bool alreadyConverted = getAuthDB().query(`
select exists(
	select column_name
	from information_schema.columns
	where
		table_name = 'site_user'
		and
		column_name = 'is_blocked'
)
	`).getScalar!bool();
	enforce(!alreadyConverted, `База данных уже сконвертирована!`);

	writeln(`Изменение таблицы site_user`);
	getAuthDB().query(`
ALTER TABLE public.site_user
	ADD COLUMN email_confirm_uuid uuid;
COMMENT ON COLUMN public.site_user.email_confirm_uuid
	IS 'Уникальный идентификатор, используемый для подтверждения адреса эл. почты пользователя';

ALTER TABLE public.site_user
	ADD COLUMN is_blocked boolean;
COMMENT ON COLUMN public.site_user.is_blocked
	IS 'Признак, что пользователь заблокирован, и вход под ним запрещен';

ALTER TABLE public.site_user
	ADD COLUMN is_email_confirmed boolean;
COMMENT ON COLUMN public.site_user.is_email_confirmed
	IS 'Признак подтверждения адреса эл. почты пользователем';
	`);

	writeln(`Изменение таблицы session`);
	getAuthDB().query(`
ALTER TABLE public.session
	ADD COLUMN created timestamp without time zone;
COMMENT ON COLUMN public.session.created
	IS 'Дата создания сессии пользователя';
--Удаляем старую колонку
ALTER TABLE public.session DROP COLUMN expires;
	`);
}