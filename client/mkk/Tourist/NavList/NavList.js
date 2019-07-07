define('mkk/Tourist/NavList/NavList', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'mkk/Tourist/PlainList/PlainList',
	'css!mkk/Tourist/NavList/NavList'
], function (FirControl, FirHelpers) {
return FirClass(
	function TouristNavList(opts) {
		this.superctor(TouristNavList, opts);
		this._listView = this.getChildByName(this.instanceName() + 'View');
		this._listView.subscribe('onTouristListLoaded', this._onTouristListLoaded.bind(this));
		this._listView.subscribe('itemActivated', this._onTouristItemActivated.bind(this));
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: null,
			navOpt: 'nav',
			replaceURIState: true
		});
	}, FirControl, {
		_onTouristListLoaded: function(ev, rs, nav) {
			this._notify.apply(this, ['onTouristListLoaded'].concat([].slice.call(arguments, 1)));
		},
		_onTouristItemActivated: function() {
			// Пробрасываем событие внутр. компонента наружу
			this._notify.apply(this, ['itemActivated'].concat([].slice.call(arguments, 1)));
		},
		_getQueryParams: function() {
			return {
				nav: this._paging.getNavParams(),
				filter: (typeof(this._filterGetter) === 'function'? this._filterGetter(): {})
			};
		},
		_getViewParams: function() {
			return {
				mode: this._mode,
				itemIcon: this._itemIcon
			};
		},
		_reloadControl: function() {
			this._listView._reloadControl(null, {
				queryParams: this._getQueryParams(),
				viewParams: this._getViewParams(),
				RPCMethod: this._getRPCMethod()
			});
		},
		setFilterGetter: function(val) {
			if( typeof(val) !== 'function' && val != null ) {
				throw new Error('Expected filter getter function');
			}
			this._filterGetter = val;
		}
	});
});