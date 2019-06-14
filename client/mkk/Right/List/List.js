define('mkk/Right/List/List', [
	'fir/controls/FirControl',
	'css!mkk/Right/List/List'
], function (FirControl) {
return FirClass(
	function RightList(opts) {
		this.superproto.constructor.call(this, opts);
		this._rightEditDlg = this.getChildByName('rightEditDlg');
		this._subscr(function() {
			this._elems('rightList').on('click', this._onListItem_click.bind(this));
			this._elems('addRight').on('click', this._onAddRightBtn_click.bind(this))
		});
		this._unsubscr(function() {
			this._elems('rightList').off('click');
		});
	}, FirControl, {
		_onAddRightBtn_click: function() {
			this._rightEditDlg.open({
				queryParams: {
					objectNum: this._objectNum
				}
			});
		},
		_onListItem_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('itemActionBtn'));
			if( !el || !el.length )
				return;
			var action = el.data('mkkAction');
			switch( action ) {
				case 'editRule': {
					this._rightEditDlg.open({
						queryParams: {
							num: parseInt(el.data('recordNum'), 10) || null
						}
					});
					break;
				}
				default: break;
			}
		}
	}
);
});