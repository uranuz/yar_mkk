define('mkk/DocumentList/DocumentList', [
	'fir/controls/FirControl',
	'mkk/Pagination/Pagination',
	'mkk/DocumentEdit/DocumentEdit',
	'css!mkk/DocumentList/DocumentList'
], function (FirControl, DatctrlHelpers) {
	__extends(DocumentList, FirControl);

	function DocumentList(opts) {
		FirControl.call(this, opts);
		this._documentEdit = this.getChildInstanceByName('documentEdit');
		this._documentEdit.subscribe('onDocumentLoaded', self._)
	}
	return __mixinProto(DocumentList, {
		_subscribeInternal: function() {
			this._elems('addDocBtn').on('click', this._onAddDocBtn_click.bind(this));
			this._elems('linkList').on('click', this._onLinkEditBtn_click.bind(this));
		},
		_unsubscribeInternal: function() {
			this._elems('addDocBtn').off('click');
			this._elems('linkList').off('click');
		},
		_onAddDocBtn_click: function() {
			this._documentEdit.openDialog(null);
		},
		_onLinkEditBtn_click: function(ev) {
			var
				el = $(ev.target).closest(this._elemClass('linkEditBtn')),
				self = this;
			if( !el || !el.length ) {
				return;
			}
			this._documentEdit.openDialog(el.data('documentNum'));
		}
	});
});