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
			new RemoteCodeLoader('/dyn/server/template'));
		progCache.getIvyModule('mkk.PohodList', function(prog) {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "pohod.list",
				params: {
					filter: {},
					nav: {}
				},
				success: function(data) {
					data = FirIvyHelpers.tryExtractLvlContainers(data);
					var
						res = prog.run({
							pohodList: data.rs,
							pohodNav: data.nav,
							userRights: new IvyUserRights()
						}),
						rendered = iu.toString(res);
					self._elems('content').html(rendered);
				},
				error: function(res) {
					$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
				}
			});
		});
		return;
	}
	return __mixinProto(JSRender, {});
});