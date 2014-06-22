module mkk_site.site_config;

import std.json, std.file, std.path;

import mkk_site.utils;


/++
$(LOCALE_EN_US
	Function resolves paths that are set by $(D_PARAM jsonPaths). All paths could be realtive 
	to root path, which is path with name $(D_PARAM rootPathName). Root path can't be
	relative but can be empty or not exist inside $(D_PARAM jsonPaths). In that case it
	will be replaced by defaultPaths[rootPathName]
	Params:
		jsonPaths = JSONValue that must be object, representing list of paths
			using format "pathName" : "path"
		defaultPaths = Set of path that are used when some of path needed
			by application are not present in config or empty
		rootPathName = Path name considered as name for root path.
			Root path is used for resolving relative path in config
			or inside $(D_PARAM defaultPaths) array
)
$(LOCALE_RU_RU
	Функция выполняет разрешение путей в конфигурации
	Params:
	jsonPaths = JSONValue значения типа JSON_TYPE.OBJECT, представляющие список путей
	в формате "названиеПути" : "путь"
	defaultPaths = Набор путей по умолчанию на случай, если какие-то из требуемых 
		путей окажутся не задаными
	rootPathName = Название для пути, рассматриваемого как корневой путь
)
+/
string[string] resolveConfigPaths(bool shouldExpandTilde = false)( JSONValue jsonPaths, string[string] defaultPaths, string rootPathName = "rootPath")
{
	assert( rootPathName.length > 0, "Root path name must not be empty" );
	string[string] result;
	
	assert( jsonPaths.type == JSON_TYPE.OBJECT, `Config paths JSON value must be an object!!!` );
	
	string rootPath = null;
	
	if( rootPathName in jsonPaths.object )
	{
		assert( jsonPaths[rootPathName].type == JSON_TYPE.STRING || 
			jsonPaths[rootPathName].type == JSON_TYPE.NULL, 
			`Config path "` ~ rootPathName  ~ `" value must be string or null!!!` 
		);
		
		if( jsonPaths[rootPathName].type == JSON_TYPE.STRING )
		{
			static if( shouldExpandTilde )
				rootPath = jsonPaths[rootPathName].str.expandTilde();
			else
				rootPath = jsonPaths[rootPathName].str;
		}
			
	}
	
	if( !rootPath )
	{
		static if( shouldExpandTilde )
			rootPath = defaultPaths.get(rootPathName, null).expandTilde();
		else
			rootPath = defaultPaths.get(rootPathName, null);
	}
	
	assert( rootPath.length > 0 && isAbsolute(rootPath), `Config path "` ~ rootPathName  ~ `" value must be absolute!!!` );
	
	foreach( string pathName, jsonPath; jsonPaths )
	{
		if( pathName == rootPathName )
			continue; //Ignore root path here
		
		//Extracting only non-empty strings
		if( jsonPath.type == JSON_TYPE.STRING && jsonPath.str.length > 0 )
		{	
			static if( shouldExpandTilde )
				result[pathName] = buildNormalPath( rootPath, jsonPath.str.expandTilde() );
			else
				result[pathName] = buildNormalPath( rootPath, jsonPath.str );
		}
	}

			
	foreach( string pathName, path; defaultPaths )
	{
		if( pathName == rootPathName )
			continue; //Ignore root path here
		
		if( pathName !in result )
		{
			static if( shouldExpandTilde )
				result[pathName] = buildNormalPath( rootPath, defaultPaths[pathName].expandTilde() );
			else
				result[pathName] = buildNormalPath( rootPath, defaultPaths[pathName] );
		}
	}
	
	result[rootPathName] = rootPath;
	
	return result;
}

string[string] resolveConfigDatabases(JSONValue jsonDatabases)
{
	import std.conv, std.string;
	
	string[string] result;
	
	foreach( string dbCaption, jsonDb; jsonDatabases )
	{
		string connStr = "";
		bool isHostFound = false;
		
		if( "dbname" in jsonDb.object )
		{
			if( jsonDb["dbname"].type == JSON_TYPE.STRING )
			{
				connStr ~= "dbname=" ~ jsonDb["dbname"].str ~ " ";
			
			}
		}
		
		if( "host" in jsonDb.object )
		{
			if( jsonDb["host"].type == JSON_TYPE.STRING )
			{
				isHostFound = true;
				connStr ~= "host=" ~ jsonDb["host"].str ~ " ";
			
			}
		}
	
		if( "port" in jsonDb.object )
		{
			if( jsonDb["host"].type == JSON_TYPE.UINTEGER )
			{
				if( !isHostFound )
					connStr ~= "host=127.0.0.1";
					
				connStr ~= ":" ~ jsonDb["host"].uinteger.to!string ~ " ";
			}
		}
		
		if( "username" in jsonDb.object )
		{
			if( jsonDb["username"].type == JSON_TYPE.STRING )
			{
				connStr ~= "user=" ~ jsonDb["username"].str ~ " ";
			
			}
		}
		
		if( "password" in jsonDb.object )
		{
			if( jsonDb["password"].type == JSON_TYPE.STRING )
			{
				connStr ~= "password=" ~ jsonDb["password"].str ~ " ";
			
			}
		}
		
		result[dbCaption] = strip(connStr);
	}
	
	return result;
}
