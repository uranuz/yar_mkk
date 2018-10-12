define('mkk/UserList/UserList', [
	'fir/controls/FirControl',
	'css!mkk/UserList/UserList'
], function (FirControl) {
	__extends(UserList, FirControl);

	function UserList(opts) {
		FirControl.call(this, opts);
		this._listBlock = this._elems('list');
		this._confirmDlg = this._elems('confirmDlg');
	}
	return __mixinProto(UserList, {
		_subscribeInternal: function() {
			this._listBlock.on('click', this._onListBlock_click.bind(this));
		},
		_onListBlock_click: function(ev) {
			if ( $(ev.target).is(this._elemClass('confirmRegBtn')) ) {
				var
					itemRow = $(ev.target).closest(this._elemClass('listItem')),
					itemNum = parseInt(itemRow.data('mkk-num'), 10);
				this._confirmDlg.dialog({
					modal: true
				});
			}
		}
	});
});