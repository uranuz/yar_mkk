define('mkk/User/List/List', [
	'fir/controls/FirControl',
	'css!mkk/User/List/List'
], function (FirControl) {
return FirClass(
	function UserList(opts) {
		this.superproto.constructor.call(this, opts);
		this._listBlock = this._elems('list');
		this._confirmDlg = this._elems('confirmDlg');
		this._subscr(function() {
			this._listBlock.on('click', this._onListBlock_click.bind(this));
		});
		this._unsubscr(function() {
			this._listBlock.off('click');
		});
	}, FirControl, {
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