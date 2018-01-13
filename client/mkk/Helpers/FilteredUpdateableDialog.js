define('mkk/Helpers/FilteredUpdateableDialog', [
	'mkk/Helpers/FilteredUpdateable'
], function (FilteredUpdateable) {
	__extends(FilteredUpdateableDialog, FilteredUpdateable);
	function FilteredUpdateableDialog() {}

	return new (__mixinProto(FilteredUpdateableDialog, {
		openDialog: function(filter) {
			if( filter != null ) {
				this.setFilter(filter);
			}
			this._reloadControl();
		},
		setDialogOptions: function(opts) {
			this._dialogOpts = opts;
		},
		_onAfterLoad: function() {
			this.superproto._onAfterLoad.call(this, arguments);
			if( this._isDialogExtraReload ) {
				this._container.dialog(this._dialogOpts);
			} else {
				this._isDialogExtraReload = true;
			}
		}
	}));
});