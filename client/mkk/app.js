define('mkk/app', [
	'ivy/engine',
	'ivy/engine_config',
	'fir/ivy/RemoteModuleLoader',
	"fir/controls/Loader/Manager",
	"fir/controls/Loader/IvyServerFactory",
	"fir/controls/Loader/IvyServerRender",
	'fir/ivy/directive/standard_factory',
	"fir/controls/ControlManager",
	"fir/security/right/IvyRuleFactory",
	"fir/security/right/GlobalVarSource",
	"fir/security/right/Controller",
	"fir/security/right/UserIdentity",
	"fir/security/right/UserRights",
	"mkk/ModuleLoader",
	"mkk/GeneralTemplate/GeneralTemplate",
	"mkk/app.scss"
], function(
	IvyEngine,
	IvyEngineConfig,
	RemoteModuleLoader,
	LoaderManager,
	IvyServerFactory,
	IvyServerRender,
	StandardFactory,
	ControlManager,
	IvyRuleFactory,
	GlobalVarSource,
	AuthController,
	UserIdentity,
	UserRights,
	ModuleLoader
) {
return FirClass(
	function MKKApp() {
		var
			ivyConfig = new IvyEngineConfig(),
			ivyModuleLoader = new RemoteModuleLoader('/dyn/server/template');
		ivyConfig.directiveFactory = StandardFactory();

		this._ivyEngine = new IvyEngine(ivyConfig, ivyModuleLoader);
		this._ivyEngine.getByModuleName('mkk.AccessRules');

		this._accessController = new AuthController(
			new IvyRuleFactory(this._ivyEngine), new GlobalVarSource());
		this._userIdentity = new UserIdentity(window.userRightData.user);
		this._userRights = new UserRights(this._userIdentity, this._accessController);
	
		LoaderManager.add(
			new IvyServerFactory(
				this._ivyEngine,
				this._userIdentity,
				this._userRights,
				window.userRightData.vpaths));
		LoaderManager.add(new IvyServerRender());
		this._moduleLoader = new ModuleLoader(window.webpackLibs);
		ControlManager.setModuleLoader(this._moduleLoader);
		ControlManager.reviveMarkup($('body'));
	}
);
});