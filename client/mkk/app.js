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
	"fir/controls/ControlManager",
	"css!mkk/app"
], function(
	IvyEngine,
	IvyEngineConfig,
	RemoteModuleLoader,
	LoaderManager,
	IvyServerFactory,
	IvyServerRender,
	ControlManager
) {
	window.ivyEngine = new IvyEngine(
		new IvyEngineConfig(),
		new RemoteModuleLoader('/dyn/server/template'));
	LoaderManager.add(new IvyServerFactory(window.ivyEngine));
	LoaderManager.add(new IvyServerRender());
	ControlManager.launchMarkup($('body'));
});
define('mkk/init', ['fir/common/globals'], function() {
	require(['mkk/app'], function() {});
});

require(['mkk/init'], function() {});