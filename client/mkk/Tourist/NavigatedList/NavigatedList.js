define('mkk/Tourist/NavigatedList/NavigatedList', [
	'fir/controls/FirControl',
	'mkk/Tourist/PlainList/PlainList',
	'css!mkk/Tourist/NavigatedList/NavigatedList'
], function (FirControl) {
return FirClass(
	function TouristNavigatedList(opts) {
		this.superproto.constructor.call(this, opts);
		this._listView = this.getChildByName(this.instanceName() + 'View');
		this.setFilter(opts.filter);
		this.setMode(opts.mode);
		this._listView.subscribe('onTouristListLoaded', this._onTouristListLoaded.bind(this));
		this._listView.subscribe('itemActivated', this._onTouristItemActivated.bind(this));
		this._pagination = this.getChildByName(this.instanceName() + 'Paging');
		this._pagination.subscribe('onSetCurrentPage', this._onSetCurrentPage.bind(this));
	}, FirControl, {
		setFilter: function(filter) {
			this._listView.setFilter(filter);
		},
		setMode: function(mode) {
			this._listView.setMode(mode);
		},
		setNavigation: function(nav) {
			this._listView.setNavigation(nav);
		},
		getTouristList: function() {
			return this._listView.getTouristList(nav);
		},
		_onTouristListLoaded: function(ev, rs, nav) {
			this._pagination.setNavigation(nav);
			this._notify.apply(this, ['onTouristListLoaded'].concat([].slice.call(arguments, 1)));
		},
		_onTouristItemActivated: function() {
			// Пробрасываем событие внутр. компонента наружу
			this._notify.apply(this, ['itemActivated'].concat([].slice.call(arguments, 1)));
		},
		_onSetCurrentPage: function() {
			this._listView.setNavigation({
				offset: this._pagination.getOffset(),
				pageSize: this._pagination.getPageSize() || 10
			});
			this._listView._reloadControl();
		},
		_reloadControl: function() {
			this._onSetCurrentPage();
		}
	});
});