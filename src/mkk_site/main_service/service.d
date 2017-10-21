module mkk_site.main_service.service;

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
MKKMainService Service() @property {
	assert( _mkk_main_service, `MKK main service is not initialized!` );
	return _mkk_main_service;
}

import mkk_site.main_service.db_manager;

// Возвращает ссылку на экземпляр менеджера соединений БД основного сервиса МКК
MKKMainDatabaseManager DBManager() @property {
	assert( _mkk_main_service, `MKK main database manager is not initialized!` );
	return _mkk_main_db_manager;
}

// Метод для получения экземпляра объекта подключения к основной БД сервиса МКК
IDatabase getCommonDB() @property {
	return DBManager.commonDB;
}

// Метод для получения экземпляра объекта подключения к БД аутентификации сервиса МКК
IDatabase getAuthDB()  @property {
	return DBManager.authDB;
}

// Класс основного сервиса МКК. Создаётся один глобальный экземпляр на процесс
// Служит для чтения и хранения конфигурации, единого доступа к логам,
// маршрутизации и выполнения аутентификации запросов
class MKKMainService
{
	import webtank.common.loger;
	import webtank.db.database;
	import webtank.db.postgresql;
	import webtank.net.http.context;
	import webtank.net.http.json_rpc_handler;
	import webtank.net.http.handler;

	import mkk_site.site_data;
	import mkk_site.config_parsing;
	import mkk_site.access_control;

	import std.json: JSONValue;

	static immutable string serviceName = "yarMKKMain";

	alias ServiceAccessController = MKKMainAccessController!(getAuthDB);
private:
	JSONValue _jsonConfig;
	string[string] _fileSystemPaths;
	string[string] _virtualPaths;

	HTTPRouter _rootRouter;
	JSON_RPC_Router _jsonRPCRouter;

	/// Основной объект для ведения журнала сайта
	Loger _loger;

	/// Объект для приоритетных записей журнала сайта
	Loger _prioriteLoger;

	// Объект для логирования драйвера базы данных
	Loger _databaseLoger;

	ServiceAccessController _accessController;

public:
	this()
	{
		readConfig();
		_startLoging();

		_rootRouter = new HTTPRouter;
		assert( "siteJSON_RPC" in _virtualPaths, `Failed to get JSON-RPC virtual path!` );
		_jsonRPCRouter = new JSON_RPC_Router( _virtualPaths["siteJSON_RPC"] ~ "{remainder}" );
		_rootRouter.addHandler(_jsonRPCRouter);

		_accessController = new ServiceAccessController;
		_subscribeRoutingEvents();
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

	JSONValue JSONConfig() @property {
		return _jsonConfig;
	}

	string[string] virtualPaths() @property {
		return _virtualPaths;
	}

	string[string] fileSystemPaths() @property {
		return _fileSystemPaths;
	}

	private void _startLoging()
	{
		if( !_loger ) {
			assert( "siteEventLogFile" in _fileSystemPaths, `Failed to get event log file path!` );
			_loger = new ThreadedLoger( cast(shared) new FileLoger(_fileSystemPaths["siteEventLogFile"], LogLevel.info) );
		}

		if( !_prioriteLoger ) {
			assert( "sitePrioriteLogFile" in _fileSystemPaths, `Failed to get priorite log file path!` );
			_prioriteLoger = new ThreadedLoger( cast(shared) new FileLoger(_fileSystemPaths["sitePrioriteLogFile"], LogLevel.info) );
		}

		if( !_databaseLoger ) {
			assert( "siteDatabaseLogFile" in _fileSystemPaths, `Failed to get database log file path!` );
			_databaseLoger = new ThreadedLoger( cast(shared) new FileLoger(_fileSystemPaths["siteDatabaseLogFile"], LogLevel.dbg) );
		}
	}

	Loger loger() @property {
		assert( _rootRouter, `Main service loger is not initialized!` );
		return _loger;
	}

	Loger prioriteLoger() @property {
		assert( _prioriteLoger, `Main service priorite loger is not initialized!` );
		return _prioriteLoger;
	}

	// Метод перенаправляющий логи БД в файл
	void databaseLogerMethod(DBLogInfo logInfo)
	{
		import std.datetime;
		import std.conv: text;
		if( !_databaseLoger ) {
			return;
		}
		LogEvent wtLogEvent;
		final switch(logInfo.type) {
			case DBLogInfoType.info: wtLogEvent.type = LogEventType.dbg; break;
			case DBLogInfoType.warn: wtLogEvent.type = LogEventType.warn; break;
			case DBLogInfoType.error: wtLogEvent.type = LogEventType.error; break;
		}

		wtLogEvent.text = `Database driver: ` ~ logInfo.msg;
		wtLogEvent.timestamp = std.datetime.Clock.currTime();

		_databaseLoger.writeEvent(wtLogEvent);
	}

	private string _makeExtendedErrorMsg(Throwable error)
	{
		import std.conv;
		return error.msg ~ "<br>\r\n" ~"Module: " ~ error.file ~ "(" ~ error.line.to!string ~ ") \r\n" ~ error.info.to!string;
	}

	private void _subscribeRoutingEvents() {
		import std.exception: assumeUnique;
		import std.conv;

		//Для сообщений об ошибках базового класса Throwable не используем шаблон страницы,
		//поскольку нить исполнения находится в некорректном состоянии
		_rootRouter.onError.join( (Throwable error, HTTPContext context) {
			string extendedMsg = _makeExtendedErrorMsg(error);
			static if( isMKKSiteReleaseTarget )
				string msg = error.msg;
			else
				string msg = extendedMsg;

			prioriteLoger.error(extendedMsg);
			loger.error(extendedMsg);

			throw error;
			return true; //Dummy error
		} );

		_rootRouter.onPostPoll ~= (HTTPContext context, bool isMatched) {
			if( isMatched )
			{	context._setuser( _accessController.authenticate(context) );
			}
		};

		_jsonRPCRouter.onPostPoll ~= ( (HTTPContext context, bool isMatched) {
			import std.conv: to;
			string msg = "Received JSON-RPC request. Headers:\r\n" ~ context.request.headers.toAA().to!string;
			debug msg ~=  "\r\nMessage body:\r\n" ~ context.request.messageBody;

			_loger.info(msg);
		});

		//Обработка ошибок в JSON-RPC вызовах
		_jsonRPCRouter.onError.join( (Throwable error, HTTPContext context) {
			string extendedMsg = _makeExtendedErrorMsg(error);
			static if( isMKKSiteReleaseTarget )
				string msg = error.msg;
			else
				string msg = extendedMsg;

			prioriteLoger.error(extendedMsg);
			loger.error(extendedMsg);

			throw error;
			return true; //Dummy return
		} );
	}

	HTTPRouter rootRouter() @property {
		assert( _rootRouter, `Main service root router is not initialized!` );
		return _rootRouter;
	}

	JSON_RPC_Router JSON_RPCRouter() @property {
		assert( _jsonRPCRouter, `Main service JSON-RPC router is not initialized!` );
		return _jsonRPCRouter;
	}

	ServiceAccessController accessController() @property {
		assert( _accessController, `Main service access controller is not initialized!` );
		return _accessController;
	}

}

private __gshared MKKMainService _mkk_main_service;

shared static this() {
	_mkk_main_service = new MKKMainService();
}

// Each thread uses it's own database connection manager
private MKKMainDatabaseManager _mkk_main_db_manager;

static this() {
	import mkk_site.config_parsing: getServiceDatabases, getServiceFileSystemPaths;
	auto serviceJSONConfig = Service.JSONConfig;
	// Get databases config from Service to establish connection
	_mkk_main_db_manager = new MKKMainDatabaseManager(
		getServiceDatabases(serviceJSONConfig), &(Service.databaseLogerMethod)
	);
}