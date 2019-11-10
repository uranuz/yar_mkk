define('mkk/Document/List/List', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'mkk/Document/List/List.scss'
], function (FirControl, FirHelpers) {
return FirClass(
	function DocumentList(opts) {
		this.superctor(DocumentList, opts);
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		this._documentEditDlg = this.getChildByName('documentEditDlg');
		this._documentEditDlg.subscribe('dialogControlDestroy', this._reloadControl.bind(this, 'linkList'));

		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: 'linkList',
			replaceURIState: true
		});

		this._subscr(function() {
			this._elems('addDocBtn').on('click', this._onAddDocBtn_click.bind(this));
			this._elems('linkList').on('click', this._onLinkEditBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('addDocBtn').off('click');
			this._elems('linkList').off('click');
		});
	}, FirControl, {
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
				nav: this._paging.getNavParams()
			};
		}
	});
});