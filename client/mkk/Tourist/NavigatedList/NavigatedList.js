define('mkk/Tourist/NavigatedList/NavigatedList', [
	'fir/controls/FirControl',
	'mkk/TouristPlainList/TouristPlainList',
	'mkk/Pagination/Pagination',
	'css!mkk/Tourist/NavigatedList/NavigatedList'
], function (FirControl) {
	__extends(TouristNavigatedList, FirControl);
	function TouristNavigatedList(opts) {
		FirControl.call(this, opts);
		this._listView = this.getChildInstanceByName(this.instanceName() + 'View');
		this.setFilter(opts.filter);
		this.setMode(opts.mode);
		this._listView.subscribe('onTouristListLoaded', this._onTouristListLoaded.bind(this));
		this._listView.subscribe('itemActivated', this._onTouristItemActivated.bind(this));
		this._pagination = this.getChildInstanceByName(this.instanceName() + 'Pagination');
		this._pagination.subscribe('onSetCurrentPage', this._onSetCurrentPage.bind(this));
	}
	return __mixinProto(TouristNavigatedList, {
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