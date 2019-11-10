define('mkk/Pohod/List/List', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'mkk/Pohod/PartyInfo/PartyInfo',
	'mkk/Pohod/List/Navigation/Navigation',
	'mkk/Pohod/List/List.scss'
], function(FirControl, FirHelpers) {
return FirClass(
	function PohodList(opts) {
		this.superctor(PohodList, opts);
		this._partyInfoDlg = this.getChildByName('partyInfoDlg');
		this._navigation = this.getChildByName('pohodListNavigation');

		FirHelpers.managePaging({
			control: this,
			paging: this._navigation._getPaging(),
			areaName: 'tableContentBody',
			navOpt: 'pohodNav',
			replaceURIState: true
		});
		
		this._navigation.subscribe('onSearchStart', this._reloadControl.bind(this, 'tableContentBody'));
		this._subscr(function() {
			this._elems("tableContentBody").on("click", this.onShowPartyBtn_click.bind(this));
		});

		this._unsubscr(function() {
			this._elems("tableContentBody").off();
		});
	}, FirControl, {
		onShowPartyBtn_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('showPartyBtn'));
			if( !el || !el.length ) {
				return;
			}

			var pohodNum = parseInt(el.data("pohod-num"), 10);
			this._partyInfoDlg.open({
				queryParams: {
					num: pohodNum
				}
			});
		},
		_getQueryParams: function() {
			return {
				nav: this._navigation._getPaging().getNavParams(),
				filter: this._navigation.getFilter()
			}
		}
	}
);
});