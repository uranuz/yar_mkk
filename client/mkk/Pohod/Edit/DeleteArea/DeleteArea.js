define('mkk/Pohod/Edit/DeleteArea/DeleteArea', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(DeleteArea, FirControl);

	function DeleteArea(opts) {
		FirControl.call(this, opts);
		var self = this;
		this._elems('deleteConfirmBtn').on('click', function() {
			if( self._elems('deleteConfirmField').val() === 'удалить' ) {
				self._container.dialog('close');
				self._notify('onDeleteConfirm');
			} else {
				$('<div title="Ошибка ввода">Удаление похода не подтверждено!</div>').dialog({modal: true});
			}
		});
	}
	return __mixinProto(DeleteArea, {
		showDialog: function() {
			this._elems('block').dialog({modal: true});
		}
	});
});