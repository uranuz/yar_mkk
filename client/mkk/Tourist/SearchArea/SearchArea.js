define('mkk/Tourist/SearchArea/SearchArea', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'mkk/Tourist/PlainList/PlainList',
	'css!mkk/Tourist/SearchArea/SearchArea'
], function(FirControl) {
var
	ENTER_KEY_CODE = 13,
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
		var
			self = this;

		this._resultsPanel = this._elems('searchResultsPanel');
		this._addrFilterContent = this._elems('addrFilterContent');
		this._addrFilterArrow = this._elems('addrFilterArrow');
		this._pagination = this.findInstanceByName(this.instanceName() + 'Pagination');
		this._touristList = this.findInstanceByName(this.instanceName() + 'List');

		this._pagination.subscribe('onSetCurrentPage', this._onSearchTourists.bind(this));
		this._touristList.subscribe('onTouristListLoaded', this._onTouristLoaded.bind(this));
		this._touristList.subscribe('itemActivated', function(ev, rec) {
			self._notify('itemSelect', rec);
		});
		this.setAddrFiltersCollapsed(opts.addrFiltersCollapsed);
	}, FirControl, {
		_onSubscribe: function() {
			this.superproto._onSubscribe.apply(this, arguments);
			var
				self = this,
				bindedHandler = this._onFilterInput_KeyUp.bind(this);
			searchOnEnterFields.forEach(function(fieldName) {
				self._elems(fieldName).on('keyup', bindedHandler);
			});
			this._elems('searchBtn').on('click', this._onSearch_start.bind(this));
			this._elems('addrFilterToggleBtn').on('click', this.setAddrFiltersCollapsed.bind(this, null));
		},

		_onUnsubscribe: function() {
			this.superproto._onUnsubscribe.apply(this, arguments);
			this._elems('addrFilterToggleBtn').off('click');
			var self = this;
			searchOnEnterFields.forEach(function(fieldName) {
				self._elems(fieldName).off('keyup');
			});
			this._elems('searchBtn').off('click');
		},

		setAddrFiltersCollapsed: function(val) {
			this._addrFilterContent.toggleClass('is-collapsed', val);
			this._addrFilterArrow.toggleClass('is-collapsed', val);
		},

		_onFilterInput_KeyUp: function(ev) {
			if( ev.keyCode === ENTER_KEY_CODE ) {
				this._onSearch_start(); // Запускаем поиск при нажатии на кнопку Enter на поле ввода
			}
		},

		/** Тык по кнопке поиска туристов */
		_onSearch_start: function() {
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
			var self = this;

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