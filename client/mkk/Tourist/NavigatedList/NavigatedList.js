define('mkk/Tourist/NavigatedList/NavigatedList', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'mkk/Tourist/PlainList/PlainList',
	'css!mkk/Tourist/NavigatedList/NavigatedList'
], function (FirControl, NavigationMixin) {
return FirClass(
	function TouristNavigatedList(opts) {
		this.superproto.constructor.call(this, opts);
		this._listView = this.getChildByName(this.instanceName() + 'View');
		this._listView.subscribe('onTouristListLoaded', this._onTouristListLoaded.bind(this));
		this._listView.subscribe('itemActivated', this._onTouristItemActivated.bind(this));
	}, FirControl, [NavigationMixin], {
		_onTouristListLoaded: function(ev, rs, nav) {
			this._notify.apply(this, ['onTouristListLoaded'].concat([].slice.call(arguments, 1)));
		},
		_onTouristItemActivated: function() {
			// Пробрасываем событие внутр. компонента наружу
			this._notify.apply(this, ['itemActivated'].concat([].slice.call(arguments, 1)));
		},
		_onSetCurrentPage: function() {
			this._listView._reloadControl(null, {
				queryParams: {
					nav: this._getPaging().getNavParams()
				}
			});
		},
	});
});