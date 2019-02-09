define('mkk/Tourist/SearchArea/SearchArea', [
	'fir/controls/FirControl',
	'fir/network/json_rpc',
	'fir/datctrl/helpers',
	'mkk/helpers',
	'fir/controls/Pagination/Pagination',
	'mkk/Tourist/PlainList/PlainList',
	'css!mkk/Tourist/SearchArea/SearchArea'
], function(
	FirControl,
	json_rpc,
	datctrl,
	MKKHelpers
) {
return FirClass(
	function TouristSearchArea(opts) {
		FirControl.call(this, opts);
		var self = this;

		this._resultsPanel = this._elems('searchResultsPanel');
		this._addrFilterContent = this._elems('addrFilterContent');
		this._addrFilterArrow = this._elems('addrFilterArrow');
		this._pagination = this.findInstanceByName(this.instanceName() + 'Pagination');
		this._touristList = this.findInstanceByName(this.instanceName() + 'List');

		this._elems('searchBtn').on('click', this._onSearchTourists_BtnClick.bind(this));
		this._elems('addrFilterToggleBtn').on('click', this.setAddrFiltersCollapsed.bind(this, null));

		this._pagination.subscribe('onSetCurrentPage', this._onSearchTourists.bind(this));
		this._touristList.subscribe('onTouristListLoaded', this._onTouristLoaded.bind(this));
		this._touristList.subscribe('itemActivated', function(ev, rec) {
			self._notify('itemSelect', rec);
		});
		this.setAddrFiltersCollapsed(opts.addrFiltersCollapsed);
	}, FirControl, {
		setAddrFiltersCollapsed: function(val) {
			this._addrFilterContent.toggleClass('is-collapsed', val);
			this._addrFilterArrow.toggleClass('is-collapsed', val);
		},

		/** Тык по кнопке поиска туристов */
		_onSearchTourists_BtnClick: function() {
			this._pagination.setCurrentPage(0);
			//this._onSearchTourists(); //Переход к действию по кнопке Искать
		},

		/** Поиск туристов и отображение результата в диалоге */
		_onSearchTourists: function() {
			this._touristList.setFilter({
				familyName: this._elems("familyFilter").val() || undefined, 
				givenName: this._elems("nameFilter").val() || undefined,
				patronymic: this._elems("patronymicFilter").val() || undefined,
				birthYear: parseInt(this._elems("yearFilter").val(), 10) || undefined,
				region: this._elems("regionFilter").val() || undefined,
				city: this._elems("cityFilter").val() || undefined,
				street: this._elems("streetFilter").val() || undefined
			});
			this._touristList.setNavigation({
				offset: this._pagination.getOffset(),
				pageSize: this._pagination.getPageSize() || 10
			});
			this._touristList._reloadControl();
		},

		_onTouristLoaded: function(ev, rs, nav) {
			var
				self = this,
				rec,
				searchResultsDiv = self._elems("foundTourists"),
				summaryDiv = self._elems("touristsFoundSummary"),
				navigBar = self._elems("pageNavigationBar"),
				pageCountDiv = self._elems("pageCount");

			self._resultsPanel.show();
			self._pagination.setNavigation(nav);
		},

		activate: function(place) {
			this._container.detach().appendTo(place).show();
			if( this.recordSet && this.recordSet.getLength() )
				this._resultsPanel.show();
			else
				this._resultsPanel.hide()
		},
		
		deactivate: function(place) {
			this._container.detach().appendTo('body').hide();
		}
	});
});