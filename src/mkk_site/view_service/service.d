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
	import mkk_site.view_service.ivy_custom;

	import mkk_site.view_service.uri_page_router;
	import mkk_site.config_parsing;
	import mkk_site.view_service.access_control;

	static immutable string serviceName = "yarMKKView";

private:
	import std.json: JSONValue;

	debug enum bool useTemplatesCache = false;
	else enum bool useTemplatesCache = true;
	
	HTTPRouter _rootRouter;
	MKK_ViewService_URIPageRouter _pageRouter;
	Loger _loger;
	Loger _ivyLoger;
	ProgrammeCache!(useTemplatesCache) _templateCache;
	JSONValue _jsonConfig;
	string[string] _fileSystemPaths;
	string[string] _virtualPaths;

	MKKViewAccessController _accessController;

public:
	this()
	{
		readConfig(); // Читаем конфиг при старте сервиса
		_startLoging(); // Запускаем логирование сервиса

		// Стартуем шаблонизатор
		assert( "siteIvyTemplates" in _fileSystemPaths, `Failed to get path to site Ivy templates!` );
		IvyConfig ivyConfig;
		ivyConfig.importPaths = [ _fileSystemPaths["siteIvyTemplates"] ];
		ivyConfig.fileExtension = ".html";

		// Направляем логирование шаблонизатора в файл
		ivyConfig.parserLoger = &_ivyLogerMethod;
		ivyConfig.compilerLoger = &_ivyLogerMethod;
		ivyConfig.interpreterLoger = &_ivyLogerMethod;
		ivyConfig.dirInterpreters = [
			"rsRange": new RawRSRangeInterpreter
		];

		_templateCache = new ProgrammeCache!(useTemplatesCache)(ivyConfig);

		// Организуем маршрутизацию на сервисе
		_rootRouter = new HTTPRouter;
		_pageRouter = new MKK_ViewService_URIPageRouter( "/dyn/{remainder}" );
		_rootRouter.join(_pageRouter);

		_accessController = new MKKViewAccessController;
		_subscribeRoutingEvents();
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

		assert( "siteLogs" in _fileSystemPaths, `Failed to get logs directory!` );
		if( !_loger ) {
			_loger = new ThreadedLoger(
				cast(shared) new FileLoger(
					buildNormalizedPath( _fileSystemPaths["siteLogs"], "view_service.log" ), 
					LogLevel.info
				)
			);
		}

		if( !_ivyLoger ) {
			_ivyLoger = new ThreadedLoger(
				cast(shared) new FileLoger(
					buildNormalizedPath( _fileSystemPaths["siteLogs"], "ivy.log" ), 
					LogLevel.dbg
				)
			);
		}
	}

	void _subscribeRoutingEvents()
	{
		_rootRouter.onPostPoll ~= (HTTPContext context, bool isMatched) {
			if( isMatched )
			{	context._setuser( _accessController.authenticate(context) );
			}
		};
	}

	// Метод перенаправляющий логи шаблонизатора в файл
	void _ivyLogerMethod(LogInfo logInfo) {
		import std.datetime;
		LogEvent wtLogEvent;
		final switch(logInfo.type) {
			case LogInfoType.info: wtLogEvent.type = LogEventType.dbg; break;
			case LogInfoType.warn: wtLogEvent.type = LogEventType.warn; break;
			case LogInfoType.error: wtLogEvent.type = LogEventType.error; break;
			case LogInfoType.internalError: wtLogEvent.type = LogEventType.crit; break;
		}
		wtLogEvent.text = logInfo.msg;
		wtLogEvent.prettyFuncName = logInfo.sourceFuncName;
		wtLogEvent.file = logInfo.sourceFileName;
		wtLogEvent.line = logInfo.sourceLine;
		wtLogEvent.timestamp = std.datetime.Clock.currTime();

		_ivyLoger.writeEvent(wtLogEvent);
	}
}

private __gshared MKKViewService _mkk_view_service;

shared static this() {
	_mkk_view_service = new MKKViewService();
}