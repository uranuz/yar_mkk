define('mkk/Document/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'css!mkk/Document/List/List'
], function (FirControl, NavigationMixin) {
return FirClass(
	function DocumentList(opts) {
		this.superctor(DocumentList, opts);
		this._navigatedArea = 'linkList'
		this._documentEditDlg = this.getChildByName('documentEditDlg');
		this._documentEditDlg.subscribe('dialogControlDestroy', this._onSetCurrentPage.bind(this));

		this._subscr(function() {
			this._elems('addDocBtn').on('click', this._onAddDocBtn_click.bind(this));
			this._elems('linkList').on('click', this._onLinkEditBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('addDocBtn').off('click');
			this._elems('linkList').off('click');
		});
	}, FirControl, [NavigationMixin], {
		_onAddDocBtn_click: function() {
			this._documentEditDlg.open({});
		},
		_onLinkEditBtn_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('linkEditBtn'));
			if( !el || !el.length ) {
				return;
			}
			this._documentEditDlg.open({
				queryParams: {
					num: parseInt(el.data('document-num'), 10) || null
				}
			});
		},
		_getQueryParams: function() {
			return {
				filter: {},
				nav: this.getNavParams()
			};
		}
	});
});