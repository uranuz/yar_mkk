module mkk.tools.deploy;
/++
Модуль содержит реализациию утилиты для развертывания сайта МКК

+/

static immutable PG_VERSION = `11`; // Используемая версия PostgreSQL
static immutable NODE_JS_VERSION = `12.x`; // Используемая версия NodeJS

// Путь к файлу со списком источников пакетов для PostgreSQL
static immutable PG_SOURCES_LIST_PATH = `/etc/apt/sources.list.d/pgdg.list`;

import std.getopt;
import std.file: exists, read, write, isFile, mkdirRecurse, remove, copy, symlink, getcwd;
import std.path: buildNormalizedPath, dirName, baseName;
import std.algorithm: map;
import std.process: spawnProcess, wait, spawnShell, pipe, Config, Pid;
import std.array: array;
import std.stdio;
import std.exception: enforce;

static immutable dubConfigs = [
	`main_service`,
	`view_service`,
	`history_service`,
	`dispatcher`,
	`add_user`,
	`set_user_password`,
	`gen_pw_hash`,
	`gen_session_id`,
	`server_runner`
];

void main(string[] args)
{
	string cmd;
	string userName = "yar_mkk";
	bool makeUnitFiles = false;

	getopt(args,
		`cmd`, &cmd,
		`user`, &userName,
		`makeUnit`, &makeUnitFiles
	);
	
	switch(cmd)
	{
		case `req`: {
			installRequirements();
			break;
		}
		case `site`: {
			deploySite(userName);
			break;
		}
		default: {
			writeln(
`Утилита развертывания сайта МКК.
Для запуска необходимо задать команду опцией --cmd...
Опции:
--cmd Команда развертывания. Возможные значения
	"req" - Установка основных зависимостей в систему
	"site" - Собственно разворот сайта
--user Имя пользователя, в каталог которого выполняется разворот. По-умолчанию yar_mkk. Пользователь должен существовать
`
			);
		}
	}
	
}

// Выводит сообщение о текущем действии в консоль. Ждет выполнения команды по pid'у. Выводит ошибку, если она случилась
void _waitProc(Pid pid, string action)
{
	writeln(action, `...`);
	scope(exit) {
		enforce(wait(pid) == 0, `Ошибка операции: ` ~ action);
	}
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

	//installCertBot();
}

/++ Развертывание сайта +/
void deploySite(string userName)
{
	compileAll(); // Собираем все бинарники проекта

	string siteRoot = buildNormalizedPath("/home/", userName, "sites/mkk/");
	writeln(`Развертывание сайта в каталог: `, siteRoot);
	mkdirRecurse(siteRoot);

	// Удаляем всё, что нужно в каталоге развертывания сайта (на всякий случай)
	string[] toRemove = dubConfigs.map!( (confName) {
		return `bin/mkk_` ~ confName;
	}).array;

	// Добавляем скрипт дампирования БД
	toRemove ~= `dump_databases.py`;

	foreach( suffix; toRemove )
	{
		string fullName = buildNormalizedPath(siteRoot, suffix);
		if( exists(fullName) && isFile(fullName)  ) {
			remove(fullName);
		}
	}

	string[] toSimlink = toRemove.dup;

	// Создаём символические ссылки на нужные файлы
	string workDir = getcwd();
	foreach( suffix; toSimlink )
	{
		string sourceFile = buildNormalizedPath(workDir, suffix);
		string destFile = buildNormalizedPath(siteRoot, suffix);
		if( !exists(destFile) ) {
			mkdirRecurse( dirName(destFile) );
			symlink(sourceFile, destFile);
		}
	}

	string[] toCopy = [
		"services_config.json"
	];

	// Копируем нужные файлы, если их еще нет
	foreach( suffix; toCopy )
	{
		string sourceFile = buildNormalizedPath(workDir, suffix);
		string destFile = buildNormalizedPath(siteRoot, suffix);
		if( !exists(destFile) ) {
			mkdirRecurse( dirName(destFile) );
			copy(sourceFile, destFile);
		}
	}

	addSiteToNginx();
	runNpmGrunt();
	installSystemdUnits();
}

//----- Установка основных системных зависимостей

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


void installBasicUtils()
{
	_waitProc(
		spawnShell(`sudo apt install -y htop mc curl wget unar nano`),
		`Установка основных утилиты Linux`);
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

	foreach( line; p.readEnd.byLine )
	{
		if( line.startsWith(`Codename:`) ) {
			string codeName = (cast(string) line).strip(); // Избавляемся от пробелов вокруг
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

//----- Разворот сайта МКК

/// Компиляция всех нужных бинарей сайта
void compileAll()
{
	buildTarsnap();
	
	string workDir = getcwd();
	foreach( folder; [`ivy`, `webtank`, `yar_mkk`] )
	{
		immutable string sourceFolder = buildNormalizedPath(workDir, `..`, folder);
		_waitProc(
			spawnProcess([`dub`, `add-local`, sourceFolder]),
			`Добавление пути к локальному dub-пакету: ` ~ sourceFolder);
	}
	
	foreach( string confName; dubConfigs )
	{
		_waitProc(
			spawnProcess([`dub`, `build`, `:` ~ confName, `--build=release`]),
			`Сборка конфигурации: ` ~ confName);
	}
}

static immutable TARSNAP_URL = `https://www.tarsnap.com/download/tarsnap-autoconf-1.0.39.tgz`;
void buildTarsnap()
{
	immutable string workDir = getcwd();
	immutable string sourcesDir = buildNormalizedPath(workDir, `..`);
	immutable tarsnapBaseName = baseName(TARSNAP_URL, `.tgz`);

	_waitProc(
		spawnShell(`sudo apt-get install -y gcc libc6-dev make libssl-dev zlib1g-dev e2fslibs-dev`),
		`Установка зависимостей для сборки tarsnap`);

	immutable string tarsnapArchivePath = buildNormalizedPath(sourcesDir, baseName(TARSNAP_URL));
	_waitProc(
		spawnProcess([`rm`, tarsnapArchivePath]),
		`Удаление старого архива tarsnap`);

	_waitProc(
		spawnProcess([`wget`, TARSNAP_URL], null, Config.none, sourcesDir),
		`Скачивание исходников для tarsnap`);

	immutable string tarsnapDir = buildNormalizedPath(sourcesDir, tarsnapBaseName);
	if( exists(tarsnapDir) )
	{
		_waitProc(
			spawnShell(
				`rm -rf ` ~ tarsnapBaseName ~ `/* && rmdir ` ~ tarsnapBaseName ~ ` `,
				null, Config.none, sourcesDir),
			`Удаление старой сборки tarsnap`);
	}

	_waitProc(
		spawnProcess([`unar`, baseName(TARSNAP_URL)], null, Config.none, sourcesDir),
		`Разархивирование исходников для tarsnap`);

	_waitProc(
		spawnShell(`./configure`, null, Config.none, tarsnapDir),
		`Конфигурирование tarsnap`);

	_waitProc(
		spawnProcess([`make`, `all`], null, Config.none, tarsnapDir),
		`Сборка tarsnap`);

	writeln(`Копирование библиотек tarsnap...`);
	foreach( libName; [`libtarsnap_sse2.a`, `libtarsnap.a`] )
	{
		copy(
			buildNormalizedPath(tarsnapDir, `lib`, libName),
			buildNormalizedPath(workDir, `lib`, libName)
		);
	}
}

static immutable NGINX_CONF_FILE = `config/nginx/yar-mkk.ru`;
void addSiteToNginx()
{
	writeln(`Добавляем конфиг сайта в nginx...`);
	enforce(
		exists(`/etc/nginx/sites-available`),
		`Не найден каталог sites-available. Проверьте установку nginx`);
	enforce(
		exists(`/etc/nginx/sites-enabled`),
		`Не найден каталог sites-enabled. Проверьте установку nginx`);

	string workDir = getcwd();
	immutable string sourceFile = buildNormalizedPath(workDir, NGINX_CONF_FILE);
	immutable string availableFile = buildNormalizedPath(`/etc/nginx/sites-available`, baseName(NGINX_CONF_FILE));
	//copy(sourceFile, availableFile);

	_waitProc(
		spawnShell(`sudo cp "` ~ sourceFile ~ `" "` ~ availableFile ~ `"`),
		`Копирование конфига сайта в nginx`);

	writeln(`Добавление ссылки на конфиг сайта nginx в sites-enabled`);
	immutable string enabledFile = buildNormalizedPath(`/etc/nginx/sites-enabled`, baseName(NGINX_CONF_FILE));
	//symlink(availableFile, enabledFile);

	if( exists(enabledFile) )
	{
		_waitProc(
			spawnShell(`sudo unlink "` ~ enabledFile ~ `"`),
			`Удаление старой ссылки в sites-enabled`);
	}

	_waitProc(
		spawnShell(`sudo ln -s "` ~ availableFile ~ `" "` ~ enabledFile ~ `"`),
		`Добавление ссылки на конфиг nginx сайта в sites-enabled`);

	_waitProc(
		spawnShell(`sudo systemctl restart nginx`),
		`Применение конфигурации nginx`);
}

static immutable NPM_FOLDERS = [`ivy`, `fir`, `yar_mkk`];
void runNpmGrunt()
{
	foreach( folder; NPM_FOLDERS )
	{
		_waitProc(
			spawnShell(`npm install`),
			`Установка/ обновление npm пакетов для: ` ~ folder);

		_waitProc(
			spawnShell(`grunt`),
			`Запуск задач grunt для: ` ~ folder);
	}
}

static immutable string[] MKK_SERVICES = [`main`, `view`, `history`];
static immutable string SYSTEMD_UNITS_DIR = `/etc/systemd/system`;
void installSystemdUnits()
{
	string workDir = getcwd();
	foreach( srvName; MKK_SERVICES )
	{
		immutable string sourcePath = buildNormalizedPath(workDir, `config/systemd`, `mkk_` ~ srvName ~ `.service`);
		_waitProc(
			spawnShell(`sudo cp "` ~ sourcePath ~ `" "` ~ SYSTEMD_UNITS_DIR ~ `"`),
			`Установка systemd юнита для: ` ~ srvName);
	}

	writeln(`Перезагрузка демона systemd...`);
	_waitProc(
		spawnShell(`sudo systemctl daemon-reload`),
		`Перезагрузка демона systemd`);

	foreach( srvName; MKK_SERVICES )
	{
		immutable string unitName = `mkk_` ~ srvName ~ `.service`;
		_waitProc(
			spawnShell(`sudo systemctl restart ` ~ unitName),
			`Запуск systemd юнита для: ` ~ srvName);
	}

	foreach( srvName; MKK_SERVICES )
	{
		immutable string unitName = `mkk_` ~ srvName ~ `.service`;
		_waitProc(
			spawnShell(`sudo systemctl restart ` ~ unitName),
			`Включение systemd юнита для: ` ~ srvName);
	}
}

/++
string readUnitTemplate(string serviceName)
{
	string fileName = "./config/systemd/mkk_" ~ serviceName ~ ".service";
	enforce(
		exists(fileName) && isFile(fileName),
		`Unit template for service doesn't exists: ` ~ fileName
	);
	return cast(string) read(fileName);
}
+/