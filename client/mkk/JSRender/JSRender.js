define('mkk/JSRender/JSRender', [
	'fir/controls/FirControl',
	'ivy/ProgrammeCache',
	'ivy/RemoteCodeLoader',
	'ivy/utils',
	'fir/network/json_rpc',
	'fir/datctrl/ivy/helpers',
	'fir/datctrl/ivy/UserRights'
], function(
	FirControl,
	ProgrammeCache,
	RemoteCodeLoader,
	iu,
	json_rpc,
	FirIvyHelpers,
	IvyUserRights
) {
	__extends(JSRender, FirControl);

	function JSRender(opts) {
		FirControl.call(this, opts);
		var
			self = this,
			progCache = new ProgrammeCache(
			new RemoteCodeLoader('/dyn/server/template')),
			waitedSources = 3,
			prog = null,
			progData = {};
		
		function tryRunRender() {
			--waitedSources;
			if( waitedSources <= 0 ) {
				progData.userRights = new IvyUserRights();
				progData.filter = {};
				var
					res = prog.run(progData),
					rendered = iu.toString(res);
				self._elems('content').html(rendered);
			}
		}
		
		progCache.getIvyModule('mkk.PohodList', function(res) {
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
	}
	return __mixinProto(JSRender, {});
});