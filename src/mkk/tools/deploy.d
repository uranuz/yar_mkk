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
import std.process: spawnProcess, wait, spawnShell, pipe, Config;
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

/++ Развертывание сайта +/
void deploySite(string userName)
{
	compileAll(); // Собираем все бинарники проекта

	string siteRoot = buildNormalizedPath("/home/", userName, "sites/mkk_site/");
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
}

/// Компиляция всех нужных бинарей сайта
void compileAll()
{
	buildTarsnap();
	
	string workDir = getcwd();
	foreach( folder; [`ivy`, `webtank`, `yar_mkk`] )
	{
		immutable string sourceFolder = buildNormalizedPath(workDir, `..`, folder);
		auto pid = spawnProcess([`dub`, `add-local`, sourceFolder]);
		scope(exit) {
			enforce(wait(pid) == 0, `Failed to add dub package: ` ~ folder);
		}
	}
	
	foreach( string confName; dubConfigs )
	{
		auto pid = spawnProcess([`dub`, `build`, `:` ~ confName, `--build=release`]);
		scope(exit) {
			enforce(wait(pid) == 0, `Compilition failed for configuration: ` ~ confName);
		}
	}
}

static immutable TARSNAP_URL = `https://www.tarsnap.com/download/tarsnap-autoconf-1.0.39.tgz`;
void buildTarsnap()
{
	immutable string workDir = getcwd();
	immutable string sourcesDir = buildNormalizedPath(workDir, `..`);
	immutable tarsnapBaseName = baseName(TARSNAP_URL, `.tgz`);

	{
		writeln(`Установка зависимостей для сборки tarsnap...`);
		auto pid = spawnShell(`sudo apt-get install -y gcc libc6-dev make libssl-dev zlib1g-dev e2fslibs-dev`);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалась установка зависимостей для сборки tarsnap`);
		}
	}

	immutable string tarsnapArchivePath = buildNormalizedPath(sourcesDir, baseName(TARSNAP_URL));
	{
		writeln(`Удаление старого архива tarsnap...`);
		auto pid = spawnProcess([`rm`, tarsnapArchivePath]);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалось удалить старый архив tarsnap`);
		}
	}
	
	{
		writeln(`Скачивание исходников для tarsnap...`);
		auto pid = spawnProcess([`wget`, TARSNAP_URL], null, Config.none, sourcesDir);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалось скачивание исходников для tarsnap`);
		}
	}

	immutable string tarsnapDir = buildNormalizedPath(sourcesDir, tarsnapBaseName);
	if( exists(tarsnapDir) )
	{
		writeln(`Удаление старой сборки tarsnap...`);
		auto pid = spawnShell(
			`rm -rf ` ~ tarsnapBaseName ~ `/* && rmdir ` ~ tarsnapBaseName ~ ` `,
			null, Config.none, sourcesDir);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалось удалить старую сборку tarsnap`);
		}
	}

	{
		writeln(`Разархивирование исходников для tarsnap...`);
		auto pid = spawnProcess([`unar`, baseName(TARSNAP_URL)], null, Config.none, sourcesDir);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалось разархивирование исходников для tarsnap`);
		}
	}

	
	{
		writeln(`Конфигурирование tarsnap...`);
		auto pid = spawnShell(`./configure`, null, Config.none, tarsnapDir);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалось конфигурирование tarsnap`);
		}
	}

	{
		writeln(`Сборка tarsnap...`);
		auto pid = spawnProcess([`make`, `all`], null, Config.none, tarsnapDir);
		scope(exit) {
			enforce(wait(pid) == 0, `Не удалась сборка tarsnap`);
		}
	}

	writeln(`Копирование библиотек tarsnap...`);
	foreach( libName; [`libtarsnap_sse2.a`, `libtarsnap.a`] )
	{
		copy(
			buildNormalizedPath(tarsnapDir, libName),
			buildNormalizedPath(workDir, `lib`, libName)
		);
	}
}

string readUnitTemplate(string serviceName)
{
	string fileName = "./config/systemd/mkk_site_" ~ serviceName ~ ".service";
	enforce(
		exists(fileName) && isFile(fileName),
		`Unit template for service doesn't exists: ` ~ fileName
	);
	return cast(string) read(fileName);
}

static immutable NPM_FOLDERS = [`ivy`, `fir`, `yar_mkk`];
void npmInstall()
{
	foreach( folder; NPM_FOLDERS )
	{
		{
			writeln(`Установка/ обновление npm пакетов для: ` ~ folder);
			auto pid = spawnShell(`npm install`);
			scope(exit) {
				enforce(wait(pid) == 0, `Произошла ошибка при установке/ обновление npm пакетов для: ` ~ folder);
			}
		}
		
		{
			writeln(`Запуск задач grunt для: ` ~ folder);
			auto pid = spawnShell(`grunt`);
			scope(exit) {
				enforce(wait(pid) == 0, `Произошла ошибка при выполнении задач grunt для: ` ~ folder);
			}
		}

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

	writeln(`Копирование конфига сайта в nginx...`);
	string workDir = getcwd();
	immutable string sourceFile = buildNormalizedPath(workDir, NGINX_CONF_FILE);
	immutable string availableFile = buildNormalizedPath(`/etc/nginx/sites-available`, baseName(NGINX_CONF_FILE));
	copy(sourceFile, availableFile);

	writeln(`Добавление ссылки на конфиг сайта nginx в sites-enabled`);
	immutable string enabledFile = buildNormalizedPath(`/etc/nginx/sites-enabled`, baseName(NGINX_CONF_FILE));
	symlink(availableFile, enabledFile);

	{
		writeln(`Применение конфигурации nginx...`);
		auto pid = spawnShell(`sudo systemctl restart nginx`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при применении конфигурации nginx`);
		}
	}
}

import std.algorithm: startsWith;
import std.string: strip;
/++ Получить кодовое имя дистрибутива Ubuntu +/
string getLinuxCodeName()
{
	writeln(`Определяю кодовое имя дистрибутива Linux...`);
	auto p = pipe();
	auto pid = spawnProcess([`lsb_release`, `-a`], std.stdio.stdin, p.writeEnd);
	scope(exit) {
		enforce(wait(pid) == 0, `Произошла ошибка при попытке получить кодовое имя дистрибутива Linux`);
	}
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

void installBasicUtils()
{
	// Установка полезных программ таких как htop, mc, curl...
	writeln(`Устанавливаем основные утилиты Linux...`);
	auto pid = spawnShell(`sudo apt install -y htop mc curl wget unar`);
	scope(exit) {
		enforce(wait(pid) == 0, `Произошла ошибка при попытке установить основные утилиты Linux`);
	}
}

/++ Установка nodejs +/
void installNodeJS()
{
	// Инструкция для установки nodejs из репозитория лежит здеся:
	// https://github.com/nodesource/distributions/blob/master/README.md
	{
		writeln(`Добавляем репозиторий для nodejs...`);
		auto pid = spawnShell(`curl -sL https://deb.nodesource.com/setup_` ~ NODE_JS_VERSION ~ ` | sudo -E bash -`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при добавлении репозитория nodejs`);
		}
	}

	{
		writeln(`Устанавливаем nodejs...`);
		aptUpdate();
		auto pid = spawnShell(`sudo apt install -y nodejs`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при установке nodejs`);
		}
	}
}

void aptUpdate()
{
	writeln(`Выполняю apt update...`);
	auto pid = spawnShell(`sudo apt update`);
	scope(exit) {
		enforce(wait(pid) == 0, `Произошла ошибка при apt update`);
	}
}


void installPostgres()
{
	writeln(`Добавляем репозиторий для postgres...`);
	immutable string linuxCodeName = getLinuxCodeName();
	immutable string sourcesDir = dirName(PG_SOURCES_LIST_PATH);
	if( !exists(sourcesDir) ) {
		mkdirRecurse(sourcesDir);
	}
	if( !exists(PG_SOURCES_LIST_PATH) ) {
		write(PG_SOURCES_LIST_PATH, `deb http://apt.postgresql.org/pub/repos/apt/ ` ~ linuxCodeName ~ `-pgdg main`);
	}

	{
		writeln(`Импортируем подпись репозитория postgres...`);
		auto pid = spawnShell(`wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при установке nodejs`);
		}
	}

	{
		writeln(`Устанавливаем postgres...`);
		aptUpdate();
		auto pid = spawnShell(`sudo apt install -y postgresql-11 libpq-dev`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при установке nodejs`);
		}
	}
}

void installNginx()
{
	{
		writeln(`Устанавливаю nginx...`);
		auto pid = spawnShell(`sudo apt install -y nginx`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при установке nginx`);
		}
	}
}

void installCertBot()
{
	// Инструкция по установке CertBot где-то здесь...
	// https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
	writeln(`Устанавливаю CertBot...`);
	aptUpdate();

	{
		writeln(`Устанавливаю software-properties-common...`);
		auto pid = spawnShell(`sudo apt-get install software-properties-common`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при установке software-properties-common`);
		}
	}

	{
		writeln(`Добавление репозитория universe...`);
		auto pid = spawnShell(`sudo add-apt-repository universe`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при добавлении репозитория universe`);
		}
	}
	
	{
		writeln(`Добавление PPA для CertBot...`);
		auto pid = spawnShell(`sudo add-apt-repository universe`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при добавлении PPA для CertBot`);
		}
	}

	aptUpdate();

	{
		writeln(`Собственно установка CertBot...`);
		auto pid = spawnShell(`sudo apt-get install certbot python-certbot-nginx`);
		scope(exit) {
			enforce(wait(pid) == 0, `Произошла ошибка при установке CertBot`);
		}
	}
}

/++ Установка всех основных требований для сайта +/
void installRequirements()
{
	aptUpdate();
	installBasicUtils();
	installNodeJS();
	installPostgres();
	installNginx();
	//installCertBot();
}