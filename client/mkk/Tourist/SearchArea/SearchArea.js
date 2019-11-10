define('mkk/Tourist/SearchArea/SearchArea', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'mkk/Tourist/PlainList/PlainList',
	'mkk/Tourist/SearchArea/SearchArea.scss'
], function(FirControl, helpers) {
var
	searchOnEnterFields = [
		'familyFilter',
		'nameFilter',
		'patronymicFilter',
		'yearFilter',
		'regionFilter',
		'cityFilter',
		'streetFilter'
	];
return FirClass(
	function TouristSearchArea(opts) {
		this.superproto.constructor.call(this, opts);

		this._resultsPanel = this._elems('searchResultsPanel');
		this._addrFilterContent = this._elems('addrFilterContent');
		this._addrFilterArrow = this._elems('addrFilterArrow');
		this._touristList = this.getChildByName(this.instanceName() + 'List');
		this._touristList.setFilterGetter(this.getListFilterParams.bind(this));
		this._touristList.subscribe('onTouristListLoaded', this._onTouristLoaded.bind(this));
		this._touristList.subscribe('itemActivated', this._onTourist_itemActivate.bind(this));
		this.setAddrFiltersCollapsed(opts.addrFiltersCollapsed);
		this._reloadList = this._reloadControl.bind(this, null);
		helpers.doOnEnter(this, searchOnEnterFields, this._reloadList);
		this._subscr(function() {
			this._elems('searchBtn').on('click', this._reloadList);
			this._elems('addrFilterToggleBtn').on('click', this.setAddrFiltersCollapsed.bind(this, null));
		});
		this._unsubscr(function() {
			this._elems('searchBtn').off('click');
			this._elems('addrFilterToggleBtn').off('click');
		});
	}, FirControl, {
		_onTourist_itemActivate: function(ev, rec) {
			this._notify('itemSelect', rec);
		},

		_reloadControl: function() {
			this._touristList._reloadControl();
		},

		setAddrFiltersCollapsed: function(val) {
			this._addrFilterContent.toggleClass('is-collapsed', val);
			this._addrFilterArrow.toggleClass('is-collapsed', val);
		},

		getListFilterParams: function() {
			return {
				familyName: this._elems("familyFilter").val() || undefined, 
				givenName: this._elems("nameFilter").val() || undefined,
				patronymic: this._elems("patronymicFilter").val() || undefined,
				birthYear: parseInt(this._elems("yearFilter").val(), 10) || undefined,
				region: this._elems("regionFilter").val() || undefined,
				city: this._elems("cityFilter").val() || undefined,
				street: this._elems("streetFilter").val() || undefined
			};
		},

		_onTouristLoaded: function(ev, rs, nav) {
			this._resultsPanel.show();
		}
	});
});