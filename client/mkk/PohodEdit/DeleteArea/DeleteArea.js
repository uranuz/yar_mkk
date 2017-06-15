define('mkk/PohodEdit/DeleteArea/DeleteArea', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(DeleteArea, FirControl);

	function DeleteArea(opts) {
		FirControl.call(this, opts);
		var self = this;
		this._elems('deleteConfirmBtn').on('click', function() {
			if( self._elems('deleteConfirmField').val() === 'удалить' ) {
				self.trigger('onDeleteConfirm');
			}
		});
	}
	return __mixinProto(DeleteArea, {
		showDialog: function() {
			this._elems('block').dialog({modal: true});
		}
	});
});