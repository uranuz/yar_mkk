define('mkk/PohodEdit/ExtraFileLinksEdit/ExtraFileLinksEdit', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(ExtraFileLinksEdit, FirControl);

	function ExtraFileLinksEdit(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(ExtraFileLinksEdit, {
		show: function() {
			this._reloadControl();
		}
	});
});