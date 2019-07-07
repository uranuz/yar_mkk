define('mkk/Tourist/PlainList/PlainList', [
	'fir/controls/FirControl',
	'css!mkk/Tourist/PlainList/PlainList'
], function (FirControl) {
return FirClass(
	function TouristPlainList(opts) {
		this.superctor(TouristPlainList, opts);
		this._subscr(function() {
			this._elems('block').on('click', '.e-touristItem', this._onItemActivated.bind(this));
		});
		this._unsubscr(function() {
			this._elems('block').off('click');
		});
		this.subscribe('onAfterLoad', function(ev, areaName, newOpts) {
			this._touristList = newOpts.touristList;
			this._mode = newOpts.mode;
			this._notify('onTouristListLoaded', this._touristList, newOpts.nav);
		});
	}, FirControl, {
		_onItemActivated: function(ev) {
			var
				num = $(ev.currentTarget).data('num'),
				rec = this._touristList.getRecord(num);
			if (this._mode === 'remove') {
				this._touristList.remove(num);
				ev.currentTarget.remove();
			}
			this._notify('itemActivated', rec);
		},
		getTouristList: function() {
			return this._touristList;
		},
		_getViewParams: function(val) {
			return {
				itemIcon: this._itemIcon,
				mode: this._mode
			};
		}
	});
});