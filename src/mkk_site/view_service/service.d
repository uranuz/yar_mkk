module mkk_site.view_service.service;

MKKViewService Service() @property {
	return _mkk_view_service;
}

class MKKViewService
{
	import webtank.net.http.handler;
	import webtank.net.http.context;
	import webtank.common.loger;

	import ivy, ivy.compiler, ivy.interpreter, ivy.common, ivy.lexer, ivy.parser;

	import mkk_site.view_service.uri_page_router;
	import mkk_site.config_parsing;

	static immutable string serviceName = "yarMKKView";

private:
	import std.json: JSONValue;

	enum bool useTemplatesCache = false;
	
	HTTPRouter _rootRouter;
	MKK_ViewService_URIPageRouter _pageRouter;
	Loger _loger;
	ProgrammeCache!(useTemplatesCache) _templateCache;
	JSONValue _jsonConfig;
	string[string] _fileSystemPaths;
	string[string] _virtualPaths;

public:
	this()
	{
		readConfig(); // Читаем конфиг при старте сервиса
		_startLoging(); // Запускаем логирование сервиса

		// Стартуем шаблонизатор
		assert( "siteIvyTemplates" in _fileSystemPaths, `Failed to get path to site Ivy templates!` );
		string[] templatesPaths = [
			_fileSystemPaths["siteIvyTemplates"]
		];
		_templateCache = new ProgrammeCache!(useTemplatesCache)(templatesPaths, ".html");

		// Организуем маршрутизацию на сервисе
		_rootRouter = new HTTPRouter;
		_pageRouter = new MKK_ViewService_URIPageRouter( "/dyn/{remainder}" );
		_rootRouter.join(_pageRouter);
	}

	HTTPRouter rootRouter() @property {
		return _rootRouter;
	}

	MKK_ViewService_URIPageRouter pageRouter() @property {
		return _pageRouter;
	}

	Loger loger() @property {
		return _loger;
	}

	ProgrammeCache!(useTemplatesCache) templateCache() @property {
		return _templateCache;
	}

	string[string] virtualPaths() @property {
		return _virtualPaths;
	}

	string[string] fileSystemPaths() @property {
		return _fileSystemPaths;
	}

	void readConfig()
	{
		import mkk_site.config_parsing: getServiceConfig, getServiceVirtualPaths, getServiceFileSystemPaths;

		import std.file: read, exists;
		import std.json;
		
		assert( exists("mkk_site_config.json"), `Services configuration file "mkk_site_config.json" doesn't exist!` );

		JSONValue fullJSONConfig = parseJSON( cast(string) read(`mkk_site_config.json`) );
		_jsonConfig = getServiceConfig(fullJSONConfig, serviceName);
		_fileSystemPaths = getServiceFileSystemPaths(_jsonConfig);
		_virtualPaths = getServiceVirtualPaths(_jsonConfig);
	}

	void _startLoging()
	{
		import std.path: buildNormalizedPath;

		if( _loger ) {
			return; // Логирование уже должно работать :)
		}
		
		assert( "siteLogs" in _fileSystemPaths, `Failed to get logs directory!` );
		string logFileName = buildNormalizedPath( _fileSystemPaths["siteLogs"], "view_service.log" );

		_loger = new ThreadedLoger( cast(shared) new FileLoger(logFileName, LogLevel.info) );
	}

}

private __gshared MKKViewService _mkk_view_service;

shared static this() {
	_mkk_view_service = new MKKViewService();
}