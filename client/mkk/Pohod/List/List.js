define('mkk/Pohod/List/List', [
	'fir/controls/FirControl',
	'mkk/Helpers/NavigationMixin',
	'mkk/Pohod/List/PartyInfo/PartyInfo',
	'mkk/Pohod/List/Navigation/Navigation',
	'css!mkk/Pohod/List/List'
], function(FirControl, NavigationMixin) {
return FirClass(
	function PohodList(opts) {
		this.superproto.constructor.call(this, opts);

		
		this._partyInfo = this.getChildByName('partyInfo');
		this._navigation = this.getChildByName('pohodListNavigation');
		this._navigatedArea = 'tableContentBody';
	}, FirControl, [NavigationMixin], {
		_onSubscribe: function() {
			NavigationMixin._onSubscribe.apply(this, arguments);
			this._elems("tableContentBody").on("click", this.onShowPartyBtn_click.bind(this));
		},
		_onUnsubscribe: function() {
			NavigationMixin._onUnsubscribe.apply(this, arguments);
			this._elems("tableContentBody").off("click");
		},
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
			return this._navigation.getChildByName(this._navigation.instanceName() + 'Paging')
		},
		_getRPCMethod: function() {
			return 'pohod.list';
		},
		_getQueryParams: function() {
			return {
				nav: this.getNavParams(),
				filter: this._navigation.getFilter()
			}
		}
	}
);
});