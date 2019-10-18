require.config({
	waitSeconds: 120,
	baseUrl: "/pub"
});

define('mkk/app', [
	'ivy/Engine',
	'ivy/EngineConfig',
	'ivy/RemoteModuleLoader',
	"fir/controls/Loader/Manager",
	"fir/controls/Loader/IvyServerFactory",
	"fir/controls/Loader/IvyServerRender",
	'ivy/directive/StandardFactory',
	'fir/ivy/RemoteCall',
	'fir/ivy/OptStorage',
	"fir/controls/ControlManager",
	"fir/security/right/IvyRuleFactory",
	"fir/security/right/GlobalVarSource",
	"fir/security/right/Controller",
	"fir/security/right/UserIdentity",
	"fir/security/right/UserRights",
	"css!mkk/app"
], function(
	IvyEngine,
	IvyEngineConfig,
	RemoteModuleLoader,
	LoaderManager,
	IvyServerFactory,
	IvyServerRender,
	StandardFactory,
	RemoteCallInterpreter,
	OptStorageInterpreter,
	ControlManager,
	IvyRuleFactory,
	GlobalVarSource,
	AccessController,
	UserIdentity,
	UserRights
) {
	var ivyConfig = new IvyEngineConfig();
	ivyConfig.directiveFactory = StandardFactory();
	ivyConfig.directiveFactory.add(new RemoteCallInterpreter());
	ivyConfig.directiveFactory.add(new OptStorageInterpreter());
	window.ivyEngine = new IvyEngine(
		ivyConfig,
		new RemoteModuleLoader('/dyn/server/template'));
	window.ivyEngine.getByModuleName('mkk.AccessRules');

	window.accessController = new AccessController(
		new IvyRuleFactory(window.ivyEngine),
		new GlobalVarSource());
	window.userIdentity = new UserIdentity(window.userRightData.user)
	window.userRights = new UserRights(window.userIdentity, window.accessController)
	
	LoaderManager.add(
		new IvyServerFactory(
			window.ivyEngine,
			window.userIdentity,
			window.userRights,
			window.userRightData.vpaths));
	LoaderManager.add(new IvyServerRender());
	ControlManager.reviveMarkup($('body'));
});
define('mkk/init', ['fir/common/globals'], function() {
	require(['mkk/app'], function() {});
});

require(['mkk/init'], function() {});