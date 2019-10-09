define('mkk/Right/Object/List/List', [
	'fir/controls/FirControl',
	'css!mkk/Right/Object/List/List'
], function (FirControl) {
return FirClass(
	function RightObjectList(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('rightObject').on('click', this._onListItem_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('rightObject').off('click');
		});
	}, FirControl, {
		_onListItem_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('rightObject'));
			if( !el || !el.length )
				return;
			var recordNum = parseInt(el.data('recordNum'), 10) || null;
			this._notify('onObjectSelect', this._objectList.getRecord(recordNum));
		}
	}
);
});