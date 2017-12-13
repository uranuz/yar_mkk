module mkk_site.tools.deploy;

import std.getopt;
import std.file: exists, read, write, isFile, mkdirRecurse, remove, copy, symlink, getcwd;
import std.path: buildNormalizedPath;
import std.algorithm: map;
import std.stdio;

void main(string[] args)
{
	string userName = "yar_mkk";
	bool makeUnitFiles = false;

	getopt(args,
		`user`, &userName,
		`makeUnit`, &makeUnitFiles
	);


	string siteRoot = buildNormalizedPath("/home/", userName, "sites/mkk_site/");
	writeln(`Deploy to path: `, siteRoot);
	mkdirRecurse(siteRoot);
	string[] toRemove = [
		"bin/mkk_site_main_service",
		"bin/mkk_site_view_service"
	];

	foreach( suffix; toRemove )
	{
		string fullName = buildNormalizedPath(siteRoot, suffix);
		if( exists(fullName) && isFile(fullName)  ) {
			remove(fullName);
		}
	}

	string[] toSimlink = toRemove.dup;

	string workDir = getcwd();
	foreach( suffix; toSimlink )
	{
		string sourceFile = buildNormalizedPath(workDir, suffix);
		string destFile = buildNormalizedPath(siteRoot, suffix);
		if( !exists(destFile) ) {
			symlink(sourceFile, destFile);
		}
	}

	string[] toCopy = [
		"mkk_site_config.json"
	];

	foreach( suffix; toCopy )
	{
		string sourceFile = buildNormalizedPath(workDir, suffix);
		string destFile = buildNormalizedPath(siteRoot, suffix);
		if( !exists(destFile) ) {
			copy(sourceFile, destFile);
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