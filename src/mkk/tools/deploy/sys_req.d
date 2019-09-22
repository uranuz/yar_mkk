module mkk.tools.deploy.sys_req;

import std.getopt;
import std.file: exists, read, write, isFile, mkdirRecurse, remove, copy, symlink, getcwd;
import std.path: buildNormalizedPath, dirName, baseName;
import std.algorithm: map;
import std.process: spawnProcess, spawnShell, pipe, Config;
import std.array: array;
import std.stdio;
import std.exception: enforce;

import mkk.tools.deploy.common: _waitProc;

static immutable PG_VERSION = `11`; // Используемая версия PostgreSQL
static immutable NODE_JS_VERSION = `12.x`; // Используемая версия NodeJS

// Путь к файлу со списком источников пакетов для PostgreSQL
static immutable PG_SOURCES_LIST_PATH = `/etc/apt/sources.list.d/pgdg.list`;

void main(string[] args)
{
	bool isHelp = false;
	getopt(args,
		`help|h`, &isHelp
	);

	if( isHelp ) {
		writeln(`Утилита выполняет установку системных зависимостей, необходимых для работы сайта МКК`);
		return;
	}

	installRequirements();
}

/++ Установка всех основных требований для сайта +/
void installRequirements()
{
	setRussianLocale();
	aptUpdate();
	installBasicUtils();
	installNodeJS();
	installPostgres();
	installNginx();
	installCertBot();
}


/++ Хотим чтобы система имела русскую локаль, и программы устанавливались в ней +/
void setRussianLocale()
{
	writeln(`Установка системной локали`);
	
	foreach( localeName; [`ru_RU.UTF-8`, `en_US.UTF-8`] )
	{
		_waitProc(
			spawnShell(`sudo locale-gen ` ~ localeName),
			`Генерация локали: ` ~ localeName);
	}

	_waitProc(
		spawnShell(`sudo update-locale LANG=ru_RU.UTF-8`),
		`Установка локали по-умолчанию ru_RU.UTF-8`);
}

/++ Обновление списка пакетов +/
void aptUpdate()
{
	_waitProc(
		spawnShell(`sudo apt update`),
		`Выполнение apt update`);
}

/++ Установка базовых программ +/
void installBasicUtils()
{
	_waitProc(
		spawnShell(`sudo apt install -y htop mc curl wget unar nano`),
		`Установка основных утилиты Linux`);
	_waitProc(
		spawnShell(`sudo apt install -y git mercurial`),
		`Установка систем контроля версий`);
}

/++ Установка nodejs +/
void installNodeJS()
{
	// Инструкция для установки nodejs из репозитория лежит здеся:
	// https://github.com/nodesource/distributions/blob/master/README.md
	_waitProc(
		spawnShell(`curl -sL https://deb.nodesource.com/setup_` ~ NODE_JS_VERSION ~ ` | sudo -E bash -`),
		`Добавление репозитория пакетов nodejs`);


	aptUpdate();
	_waitProc(
		spawnShell(`sudo apt install -y nodejs`),
		`Собственно устанавка nodejs`);


	aptUpdate();
	_waitProc(
		spawnShell(`sudo npm install -g grunt-cli`),
		`Устанавка Grunt command line interface`);
}

void installPostgres()
{
	writeln(`Установка СУБД PostgreSQL`);
	immutable string linuxCodeName = getLinuxCodeName();
	immutable string sourcesDir = dirName(PG_SOURCES_LIST_PATH);
	if( !exists(sourcesDir) ) {
		mkdirRecurse(sourcesDir);
	}
	if( !exists(PG_SOURCES_LIST_PATH) )
	{
		//writeln(`Добавление репозитория пакетов PostgreSQL в систему`);
		_waitProc(
			spawnShell(
				`echo "deb http://apt.postgresql.org/pub/repos/apt/ ` ~ linuxCodeName ~ `-pgdg main" `
				~ `| sudo tee "` ~ PG_SOURCES_LIST_PATH ~ `"`),
			`Добавление репозитория пакетов PostgreSQL в систему`);
		//write(PG_SOURCES_LIST_PATH, `deb http://apt.postgresql.org/pub/repos/apt/ ` ~ linuxCodeName ~ `-pgdg main`);

		_waitProc(
			spawnShell(`wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -`),
			`Импортируем подпись репозитория пакетов PostgreSQL`);
	}

	aptUpdate();

	_waitProc(
		spawnShell(`sudo apt install -y postgresql-11 libpq-dev`),
		`Собственно установка СУБД PostgreSQL`);
}

import std.algorithm: startsWith;
import std.string: strip;
/++ Получить кодовое имя дистрибутива Ubuntu +/
string getLinuxCodeName()
{
	auto p = pipe();
	_waitProc(
		spawnProcess([`lsb_release`, `-a`], std.stdio.stdin, p.writeEnd),
		`Определяем кодовое имя дистрибутива Linux`);

	static immutable string PREFIX = `Codename:`;
	foreach( line; p.readEnd.byLine )
	{
		if( line.startsWith(PREFIX) ) {
			string codeName = (cast(string) line)[PREFIX.length..$].strip(); // Избавляемся от пробелов вокруг
			writeln(`Кодовое имя дистрибутива Linux "` ~ codeName ~ `"`);
			return codeName;
		}
	}
	enforce(false, `Не удалось получить кодовое имя дистрибутива Linux`);
	assert(false);
}

void installNginx()
{
	_waitProc(
		spawnShell(`sudo apt install -y nginx`),
		`Установка frontend-сервера nginx`);

	// Сайт default нам не нужен в конфигурации включенных сайтов...
	immutable string nginxDefaultSite = `/etc/nginx/sites-enabled/default`;
	if( exists(nginxDefaultSite) )
	{
		_waitProc(
			spawnShell(`sudo unlink "` ~ nginxDefaultSite ~ `"`),
			`Удаление default сайта nginx из sites-enabled`);
	}
}

/++
Установка утилиты CertBot, которая нужна нам для автоматического выпуска и продлением сертификатов для сервера nginx
+/
void installCertBot()
{
	// Инструкция по установке CertBot где-то здесь...
	// https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
	writeln(`Устанавливаю CertBot...`);
	aptUpdate();

	_waitProc(
		spawnShell(`sudo apt-get install software-properties-common`),
		`Установка software-properties-common`);
	_waitProc(
		spawnShell(`sudo add-apt-repository universe`),
		`Добавление репозитория universe`);
	_waitProc(
		spawnShell(`sudo add-apt-repository universe`),
		`Добавление PPA для CertBot`);

	aptUpdate();

	_waitProc(
		spawnShell(`sudo apt-get install certbot python-certbot-nginx`),
		`Собственно установка CertBot`);
}