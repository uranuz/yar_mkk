module mkk_site.history.service.service;

import webtank.net.service.json_rpc_service: JSON_RPCService;
import mkk_site.common.service;
import webtank.ivy.service_mixin: IvyServiceMixin, IIvyServiceMixin;
import webtank.ivy.access_rule_factory: IvyAccessRuleFactory;

class MKKHistoryService: JSON_RPCService, IIvyServiceMixin
{
	import mkk_site.security.common.access_control_client: MKKAccessControlClient;
	import webtank.security.right.controller: AccessRightController;
	import webtank.security.right.remote_source: RightRemoteSource;
	import webtank.ivy.access_rule_factory: IvyAccessRuleFactory;
	import std.functional: toDelegate;

	mixin IvyServiceMixin;

	this(string serviceName)
	{
		super(serviceName,
			new MKKAccessControlClient(),
			new AccessRightController(
				new IvyAccessRuleFactory(this),
				new RightRemoteSource(this, `yarMKKMain`, `accessRight.list`)
			)
		);
		_startIvyLogging();
		_initTemplateCache();
	}

	override MKKAccessControlClient accessController() @property
	{
		auto controller = cast(MKKAccessControlClient) _accessController;
		assert(controller, `MKK access controller is null`);
		return controller;
	}
}

// Возвращает ссылку на глобальный экземпляр основного сервиса MKK
MKKHistoryService HistoryService() @property
{
	MKKHistoryService srv = cast(MKKHistoryService) Service();
	assert( srv, `View service is null` );
	return srv;
}

// Метод для получения экземпляра объекта подключения к основной БД сервиса МКК
IDatabase getHistoryDB() @property
{
	assert( _historyDB, `MKK main service common DB connection is not initialized!` );
	return _historyDB;
}

shared static this() {
	Service(new MKKHistoryService("yarMKKHistory"));
}

import webtank.db.database: IDatabase;

// Each thread uses it's own thread local instance of connection to database,
// because PostgreSQL connection is not thread safe
private IDatabase _historyDB;

static this()
{
	import webtank.net.service.config: getServiceDatabases;
	import webtank.db.postgresql: DBPostgreSQL;

	_historyDB = new DBPostgreSQL(Service.dbConnStrings["historyDB"], &HistoryService.databaseLogerMethod);
}