define('mkk/JSRender/JSRender', [
	'fir/controls/FirControl',
	'ivy/Engine',
	'ivy/EngineConfig',
	'ivy/RemoteModuleLoader',
	'ivy/utils',
	'fir/network/json_rpc',
	'fir/datctrl/ivy/helpers',
	'fir/datctrl/ivy/UserRights',
	'fir/datctrl/ivy/UserIdentity',
	'fir/controls/ControlManager'
], function(
	FirControl,
	IvyEngine,
	IvyEngineConfig,
	RemoteModuleLoader,
	iu,
	json_rpc,
	FirIvyHelpers,
	IvyUserRights,
	IvyUserIdentity,
	ControlManager
) {
return FirClass(
	function JSRender(opts) {
		this.superproto.constructor.call(this, opts);
		var
			self = this,
			progCache = new IvyEngine(
				new IvyEngineConfig(),
				new RemoteModuleLoader('/dyn/server/template')
			),
			waitedSources = 3,
			prog = null,
			progData = {};
		
		function tryRunRender() {
			--waitedSources;
			if( waitedSources <= 0 ) {
				progData.filter = {
					dates: {
						beginRangeHead: {},
						endRangeTail: {}
					}
				};
				progData.isForPrint = false;
				progData.vpaths = {};
				prog.run(progData, {
					userRights: new IvyUserRights(),
					userIdentity: new IvyUserIdentity()
				}).then(function(res) {
					var rendered = $(iu.toString(res.data));
					self._elems('content').html(rendered);
					ControlManager.launchMarkup(rendered);
				});
			}
		}
		
		progCache.getByModuleName('mkk.PohodList', function(res) {
			prog = res;
			tryRunRender();
		});

		json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "pohod.list",
			params: {
				filter: {},
				nav: {}
			},
			success: function(data) {
				data = FirIvyHelpers.tryExtractLvlContainers(data);
				progData.pohodList = data.rs;
				progData.pohodNav = data.nav;
				tryRunRender();
			},
			error: function(res) {
				$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
			}
		});

		json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "pohod.enumTypes",
			params: {
				filter: {},
				nav: {}
			},
			success: function(data) {
				progData.pohodEnums = data;
				tryRunRender();
			},
			error: function(res) {
				$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
			}
		});
		return;
	}, FirControl
);
});