module mkk.tools.deploy.site;
/++
Модуль содержит реализациию утилиты для развертывания сайта МКК
Перед использованием нужно установить системные завизимости через mkk.tools.deploy.system_req (достаточно один раз)
+/

import std.getopt;
import std.file: exists, read, write, isFile, mkdirRecurse, remove, copy, symlink, getcwd;
import std.path: buildNormalizedPath, dirName, baseName;
import std.algorithm: map;
import std.process: spawnProcess, spawnShell, pipe, Config;
import std.array: array;
import std.stdio;
import std.exception: enforce;

import mkk.tools.deploy.common: _waitProc;

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
	bool isHelp = false;
	string userName = "yar_mkk";
	string siteName;

	getopt(args,
		`help|h`, &isHelp,
		`user`, &userName,
		`site`, &siteName
	);
	bool isError = false;

	if( !siteName.length ) {
		isError = true;
		writeln(`Требуется указать сайт через опцию --site`);
	}

	if( isHelp || isError ) {
		writeln(
`Утилита развертывания сайта МКК.
Опции:
--help|h Эта справка
--user Имя пользователя, в каталог которого выполняется разворот. По-умолчанию yar_mkk. Пользователь должен существовать
--site Адрес сайта
`);
		return;
	}

	deploySite(userName, siteName);
}

/++ Развертывание сайта +/
void deploySite(string userName, string siteName)
{
	import std.algorithm: canFind;

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

	addSiteToNginx(siteName);
	runNpmGulp();
	installSystemdUnits();
	// Кастыль: создавай сертификат, если только нормальный сайт, а не локалхвост
	if( siteName.length > 0 && ![`localhost`, `127.0.0.1`].canFind(siteName) ) {
		enableCertbot(siteName);
	}
}

/// Компиляция всех нужных бинарей сайта
void compileAll()
{
	buildTarsnap();
	
	string workDir = getcwd();
	foreach( folder; [`ivy`, `webtank`, `yar_mkk`, `trifle`] )
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
	if( exists(tarsnapArchivePath) )
	{
		_waitProc(
			spawnProcess([`rm`, tarsnapArchivePath]),
			`Удаление старого архива tarsnap`);
	}

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
static immutable NGINX_DEFAULT_SITE = `yar-mkk.ru`;
void addSiteToNginx(string siteName)
{
	import std.array: replace, join;
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

	//_waitProc(
	//	spawnShell(`sudo cp "` ~ sourceFile ~ `" "` ~ availableFile ~ `"`),
	//	`Копирование конфига сайта в nginx`);

	auto sourceConfFile = File(sourceFile);
	string resultConf;
	foreach( confLine; sourceConfFile.byLine(KeepTerminator.yes) )
	{
		// Тупо заменяем дефолтный сает на другой...
		resultConf ~= confLine.replace(NGINX_DEFAULT_SITE, siteName);
	}

	auto confPipe = pipe();
	auto teePid = spawnShell(
		`sudo tee "` ~ availableFile ~ `"`,
		confPipe.readEnd);
	confPipe.writeEnd.writeln(resultConf);
	confPipe.writeEnd.flush();
	confPipe.writeEnd.close();
	//pipe.close(); // Закрываем pipe, чтобы акститься и остановицца...

	_waitProc(teePid, `Запись конфига сайта в nginx для сайта: ` ~ siteName);

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
void runNpmGulp()
{
	immutable string workDir = getcwd();
	immutable string sourcesDir = buildNormalizedPath(workDir, `..`);
	foreach( folder; NPM_FOLDERS )
	{
		immutable string folderPath = buildNormalizedPath(sourcesDir, folder);
		_waitProc(
			spawnShell(`npm install`, null, Config.none, folderPath),
			`Установка/ обновление npm пакетов для: ` ~ folder);
	}

	string mainFolder = `yar_mkk`;
	string mainFolderPath = buildNormalizedPath(sourcesDir, mainFolder);
	_waitProc(
		spawnShell(`gulp`, null, Config.none, mainFolderPath),
		`Запуск задач gulp для: ` ~ mainFolder);
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

	systemdDaemonReload();

	foreach( srvName; MKK_SERVICES )
	{
		immutable string unitName = `mkk_` ~ srvName ~ `.service`;
		_waitProc(
			spawnShell(`sudo systemctl enable ` ~ unitName),
			`Включение автозапуска systemd юнита для: ` ~ srvName);
	}

	foreach( srvName; MKK_SERVICES )
	{
		immutable string unitName = `mkk_` ~ srvName ~ `.service`;
		_waitProc(
			spawnShell(`sudo systemctl restart ` ~ unitName),
			`Запуск systemd юнита для: ` ~ srvName);
	}

	installDumpUnit();
}

void systemdDaemonReload()
{
	_waitProc(
		spawnShell(`sudo systemctl daemon-reload`),
		`Перезагрузка демона systemd`);
}

void installDumpUnit()
{
	string workDir = getcwd();
	immutable string sourcePath = buildNormalizedPath(workDir, `config/systemd`, `mkk_db_dump.service`);
	immutable string sourcePathTimer = buildNormalizedPath(workDir, `config/systemd`, `mkk_db_dump.timer`);

	_waitProc(
		spawnShell(`sudo cp "` ~ sourcePath ~ `" "` ~ SYSTEMD_UNITS_DIR ~ `"`),
		`Установка systemd юнита дампирования БД`);
	_waitProc(
		spawnShell(`sudo cp "` ~ sourcePathTimer ~ `" "` ~ SYSTEMD_UNITS_DIR ~ `"`),
		`Установка systemd таймер дампирования БД`);

	systemdDaemonReload();

	_waitProc(
		spawnShell(`sudo systemctl start mkk_db_dump.service`),
		`Пробный запуск дампирования БД`);

	_waitProc(
		spawnShell(`sudo systemctl enable mkk_db_dump.timer`),
		`Включение автозапуска systemd таймера дампирования БД`);
	
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

static immutable string HOSTMASTER_EMAIL = `hostmaster@yar-mkk.ru`;
void enableCertbot(string siteName)
{
	// Ключ -m - емайил для связи. Я х3 зачем он им
	// Ключ --non-interactive - неинтерактивный режим
	// --force-renewal форсировать обновление сертификата
	// --rsa-key-size размер ключа (по дефолту 2048)
	_waitProc(
		spawnShell(`sudo certbot --nginx -d "` ~ siteName ~ `" -m "` ~ HOSTMASTER_EMAIL 
			~ `" --agree-tos --non-interactive --rsa-key-size=4096`),
		`Добавление/ обновление автозапуска Certbot для nginx`);
}