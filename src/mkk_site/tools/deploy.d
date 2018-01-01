module mkk_site.tools.deploy;

import std.getopt;
import std.file: exists, read, write, isFile, mkdirRecurse, remove, copy, symlink, getcwd;
import std.path: buildNormalizedPath, dirName;
import std.algorithm: map;
import std.process: spawnProcess, wait;
import std.array: array;
import std.stdio;

static immutable dubConfigs = [
	`main_service`,
	`view_service`,
	`add_user`,
	`set_user_password`,
	`gen_pw_hash`,
	`gen_session_id`,
	`server_runner`
];

void main(string[] args)
{
	string userName = "yar_mkk";
	bool makeUnitFiles = false;

	getopt(args,
		`user`, &userName,
		`makeUnit`, &makeUnitFiles
	);
	
	compileAll(); // Собираем все бинарники проекта

	string siteRoot = buildNormalizedPath("/home/", userName, "sites/mkk_site/");
	writeln(`Deploy to path: `, siteRoot);
	mkdirRecurse(siteRoot);

	// Удаляем всё, что нужно в каталоге развертывания сайта (на всякий случай)
	string[] toRemove = dubConfigs.map!( (confName) {
		return `bin/mkk_site_` ~ confName;
	}).array;

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
		"mkk_site_config.json"
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
}

/// Компиляция всех нужных бинарей сайта
void compileAll()
{
	foreach( string confName; dubConfigs ) {
		auto dubPid = spawnProcess([`dub`, `build`, `:` ~ confName, `--build=release`]);
		if( wait(dubPid) != 0 ) {
			throw new Exception( `Compilition failed for configuration: ` ~ confName );
		}
	}
}

string readUnitTemplate(string serviceName)
{
	string fileName = "./mkk_site_" ~ serviceName ~ ".service";
	if( exists(fileName) && isFile(fileName) ) {
		return cast(string) read(fileName);
	}
	throw new Exception(`Unit template for service doesn't exists: ` ~ fileName);
}