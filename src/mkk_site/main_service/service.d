module mkk_site.main_service.service;

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
MKKMainService Service() @property
{
	assert( _mkk_main_service, `MKK main service is not initialized!` );
	return _mkk_main_service;
}

// Метод для получения экземпляра объекта подключения к основной БД сервиса МКК
IDatabase getCommonDB() @property
{
	assert( _commonDB, `MKK main service common DB connection is not initialized!` );
	return _commonDB;
}

// Метод для получения экземпляра объекта подключения к БД аутентификации сервиса МКК
IDatabase getAuthDB() @property
{
	assert( _authDB, `MKK main service auth DB connection is not initialized!` );
	return _authDB;
}

// Класс основного сервиса МКК. Создаётся один глобальный экземпляр на процесс
// Служит для чтения и хранения конфигурации, единого доступа к логам,
// маршрутизации и выполнения аутентификации запросов
class MKKMainService
{
	import webtank.common.loger;
	import webtank.net.http.context;
	import webtank.net.http.json_rpc_handler;
	import webtank.net.http.handler;

	import mkk_site.common.versions;
	import mkk_site.data_model.enums;
	import mkk_site.common.site_config;
	import mkk_site.security.access_control;

	import std.json: JSONValue, parseJSON;

	static immutable string serviceName = "yarMKKMain";
private:
	JSONValue _jsonConfig;
	string[string] _fileSystemPaths;
	string[string] _virtualPaths;
	string[string] _dbConnStrings;

	HTTPRouter _rootRouter;
	JSON_RPC_Router _jsonRPCRouter;

	/// Основной объект для ведения журнала сайта
	Loger _loger;

	/// Объект для приоритетных записей журнала сайта
	Loger _prioriteLoger;

	// Объект для логирования драйвера базы данных
	Loger _databaseLoger;

	MKKMainAccessController _accessController;

public:
	this()
	{
		readConfig();
		_startLoging();

		_rootRouter = new HTTPRouter;
		assert( "siteJSON_RPC" in _virtualPaths, `Failed to get JSON-RPC virtual path!` );
		_jsonRPCRouter = new JSON_RPC_Router( _virtualPaths["siteJSON_RPC"] ~ "{remainder}" );
		_rootRouter.addHandler(_jsonRPCRouter);

		import std.functional: toDelegate;
		_accessController = new MKKMainAccessController(toDelegate(&getAuthDB));
		_subscribeRoutingEvents();
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
		_dbConnStrings = getServiceDatabases(_jsonConfig);
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

	string[string] dbConnStrings() @property {
		return _dbConnStrings;
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

	import webtank.db.database: DBLogInfo, DBLogInfoType;
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
		import std.conv: text;
		return error.msg ~ "\r\n" ~"Module: " ~ error.file ~ "(" ~ error.line.text~ ") \r\n" ~ error.info.text;
	}

	private void _subscribeRoutingEvents() {
		import std.exception: assumeUnique;
		import std.conv;

		// Обработчик выполняет аутентификацию и устанавливает полученный "билет" в контекст запроса
		_rootRouter.onPostPoll ~= (HTTPContext context, bool isMatched) {
			if( isMatched ) {
				context._setuser( _accessController.authenticate(context) );
			}
		};

		// Логирование приходящих JSON-RPC запросов для отладки
		_jsonRPCRouter.onPostPoll ~= ( (HTTPContext context, bool) {
			import std.conv: to;
			string msg = "Received JSON-RPC request. Headers:\r\n" ~ context.request.headers.toAA().to!string;
			debug msg ~=  "\r\nMessage body:\r\n" ~ context.request.messageBody;

			_loger.info(msg);
		});

		//Обработка ошибок в JSON-RPC вызовах
		_rootRouter.onError.join(&this._handleError);
		_jsonRPCRouter.onError.join(&this._handleError);
	}

	// Обработчик пишет информацию о возникших ошибках при выполнении в журнал
	private bool _handleError(Throwable error, HTTPContext)
	{
		string extendedMsg = _makeExtendedErrorMsg(error);

		prioriteLoger.error(extendedMsg);
		loger.error(extendedMsg);

		throw error;
	}

	HTTPRouter rootRouter() @property {
		assert( _rootRouter, `Main service root router is not initialized!` );
		return _rootRouter;
	}

	JSON_RPC_Router JSON_RPCRouter() @property {
		assert( _jsonRPCRouter, `Main service JSON-RPC router is not initialized!` );
		return _jsonRPCRouter;
	}

	MKKMainAccessController accessController() @property {
		assert( _accessController, `Main service access controller is not initialized!` );
		return _accessController;
	}

}

// Service is process singleton object
private __gshared MKKMainService _mkk_main_service;

shared static this() {
	_mkk_main_service = new MKKMainService();
}

import webtank.db.database: IDatabase;

// Each thread uses it's own thread local instance of connection to database,
// because PostgreSQL connection is not thread safe
private IDatabase _commonDB;
private IDatabase _authDB;

static this()
{
	import mkk_site.common.site_config: getServiceDatabases;
	import webtank.db.postgresql: DBPostgreSQL;

	_commonDB = new DBPostgreSQL(Service.dbConnStrings["commonDB"], &Service.databaseLogerMethod);
	_authDB = new DBPostgreSQL(Service.dbConnStrings["authDB"], &Service.databaseLogerMethod);
}