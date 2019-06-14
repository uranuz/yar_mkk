define('mkk/Pohod/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'mkk/Pohod/List/PartyInfo/PartyInfo',
	'mkk/Pohod/List/Navigation/Navigation',
	'css!mkk/Pohod/List/List'
], function(FirControl, NavigationMixin) {
return FirClass(
	function PohodList(opts) {
		this.superctor(PohodList, opts);
		this._navigatedArea = 'tableContentBody';
		this._navProperty = 'pohodNav';
		this._partyInfo = this.getChildByName('partyInfo');
		this._navigation = this.getChildByName('pohodListNavigation');
		
		this._navigation.subscribe('onSearchStart', this._onSetCurrentPage.bind(this));
		this._subscr(function() {
			this._elems("tableContentBody").on("click", this.onShowPartyBtn_click.bind(this));
		});

		this._unsubscr(function() {
			this._elems("tableContentBody").off();
		});
	}, FirControl, [NavigationMixin], {
		onShowPartyBtn_click: function(ev) {
			var
				el = $(ev.target).closest(this._elemClass('showPartyBtn')),
				self = this;
			if( !el || !el.length ) {
				return;
			}

			var pohodNum = parseInt(el.data("pohodNum"), 10)
			if( !isNaN(pohodNum)) {
				this._partyInfo.setNum(pohodNum);
				this._partyInfo.openDialog();
			}
		},
		_getPaging: function() {
			return this._navigation._getPaging();
		},
		_getQueryParams: function() {
			return {
				nav: this._getPaging.getNavParams(),
				filter: this._navigation.getFilter()
			}
		}
	}
);
});