define('mkk/Helpers/DeleteConfirm/DeleteConfirm', [
	'fir/controls/FirControl'
], function (FirControl) {
return FirClass(
	function DeleteConfirm(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('deleteConfirmBtn').on('click', this._onDeleteBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('deleteConfirmBtn').off('click');
		});
		this.subscribe('onAfterLoad', this._onResultLoad);
	}, FirControl, {
		_onDeleteBtn_click: function() {
			if( this._elems('deleteConfirmField').val() === this._confirmWord ) {
				this._notify('onDeleteConfirm');
			} else {
				this._reloadControl('Results');
			}
		},
		_onResultLoad: function(ev, areaName) {
			if( areaName === 'Results' ) {
				this._elems('confirmForm').hide();
			}
		}
	});
});