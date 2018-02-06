module mkk_site.view_service.service;

public import mkk_site.view_service.uri_page_router;
public import webtank.net.http.handler;

MKKViewService Service() @property {
	return _mkk_view_service;
}

class MKKViewService
{
	import webtank.net.http.handler;
	import webtank.net.http.context;
	import webtank.common.loger;
	import webtank.common.event;
	import webtank.net.http.output: HTTPOutput;

	import ivy;
	import ivy.interpreter.data_node_render: renderDataNode, DataRenderType;
	import webtank.ivy;

	import mkk_site.common.site_config;
	import mkk_site.view_service.access_control;
	import mkk_site.common.utils: getAuthRedirectURI, makeErrorMsg;
	import mkk_site.view_service.utils: mainServiceCall;

	static immutable string serviceName = "yarMKKView";

private:
	import std.json: JSONValue;

	debug enum bool useTemplatesCache = false;
	else enum bool useTemplatesCache = true;

	HTTPRouter _rootRouter;
	URIPageRouter _pageRouter;
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
		ivyConfig.fileExtension = ".ivy";

		// Направляем логирование шаблонизатора в файл
		ivyConfig.parserLoger = &_ivyLogerMethod;
		ivyConfig.compilerLoger = &_ivyLogerMethod;
		ivyConfig.interpreterLoger = &_ivyLogerMethod;

		_templateCache = new ProgrammeCache!(useTemplatesCache)(ivyConfig);

		// Организуем маршрутизацию на сервисе
		_rootRouter = new HTTPRouter;
		_pageRouter = new URIPageRouter("/dyn/{remainder}");
		_rootRouter.addHandler(_pageRouter);

		_accessController = new MKKViewAccessController;
		_subscribeRoutingEvents();
	}

	HTTPRouter rootRouter() @property {
		return _rootRouter;
	}

	URIPageRouter pageRouter() @property {
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
		import mkk_site.common.site_config:
			readServiceConfigFile,
			getServiceVirtualPaths,
			getServiceFileSystemPaths,
			getServiceDatabases;

		_jsonConfig = readServiceConfigFile(serviceName);
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

	void renderResult(TDataNode content, HTTPContext context)
	{
		import std.string: toLower;
		context.response.tryClearBody();

		if( context.request.queryForm.get("generalTemplate", null).toLower() != "no" )
		{
			auto favouriteFilters = mainServiceCall(`pohod.favoriteFilters`, context);
			assert("sections" in favouriteFilters, `There is no "sections" property in pohod.favoriteFilters response`);
			assert("allFields" in favouriteFilters, `There is no "allFields" property in pohod.favoriteFilters response`);

			TDataNode payload = [
				"vpaths": TDataNode(Service.virtualPaths),
				"content":  TDataNode(content),
				"isAuthenticated": TDataNode(context.user.isAuthenticated),
				"userName": TDataNode(context.user.name),
				"authRedirectURI": TDataNode(getAuthRedirectURI(context)),
				"pohodFilterFields": TDataNode(favouriteFilters["allFields"]),
				"pohodFilterSections": TDataNode(favouriteFilters["sections"])
			];

			content = templateCache.getByModuleName("mkk.GeneralTemplate").run(payload);
		}

		static struct OutRange
		{
			private HTTPOutput _resp;
			void put(T)(T data) {
				import std.conv: text;
				_resp.write(data.text);
			}
		}

		renderDataNode!(DataRenderType.HTML)(content, OutRange(context.response));
	}

	void _subscribeRoutingEvents()
	{
		_rootRouter.onPostPoll ~= (HTTPContext context, bool isMatched) {
			if( isMatched )
			{	context._setuser( _accessController.authenticate(context) );
			} 
		};

		_pageRouter.onError.join( (Exception ex, HTTPContext context)
		{
			auto messages = makeErrorMsg(ex);
			loger.error(messages.details);
			renderResult(TDataNode(messages.userError), context);
			context.response.headers[`status-code`] = `500`;
			context.response.headers[`reason-phrase`] = `Internal Server Error`;
			return true;
		});
	}

	// Метод перенаправляющий логи шаблонизатора в файл
	void _ivyLogerMethod(LogInfo logInfo) {
		import std.datetime;
		import std.conv: text;
		LogEvent wtLogEvent;
		final switch(logInfo.type) {
			case LogInfoType.info: wtLogEvent.type = LogEventType.dbg; break;
			case LogInfoType.warn: wtLogEvent.type = LogEventType.warn; break;
			case LogInfoType.error: wtLogEvent.type = LogEventType.error; break;
			case LogInfoType.internalError: wtLogEvent.type = LogEventType.crit; break;
		}

		if( logInfo.type == LogInfoType.error || logInfo.type == LogInfoType.internalError ) {
			wtLogEvent.text = `Ivy error at: ` ~ logInfo.processedFile ~ `:` ~ logInfo.processedLine.text ~ "\n";
		}
		wtLogEvent.text ~= logInfo.msg;
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