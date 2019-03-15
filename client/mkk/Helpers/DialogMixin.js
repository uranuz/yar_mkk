define('mkk/Helpers/DialogMixin', [

], function() {
return new (FirClass(
	function DialogMixin() {}, {
		setDialogOptions: function(opts) {
			this._dialogOpts = opts;
		},
		openDialog: function(opts) {
			opts = opts || {};
			this._reloadControl(opts.areaName);
		},
		_onAfterLoad: function(state) {
			this.superproto._onAfterLoad.apply(this, arguments);
			if( state.replaceMarkup ) {
				var area = this._getAreaElement(state.areaName);
				area.dialog(this._dialogOpts);
			}
		}
	}));
});