define('mkk/Document/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'mkk/Document/Edit/Edit',
	'css!mkk/Document/List/List'
], function (FirControl, DatctrlHelpers) {
return FirClass(
	function DocumentList(opts) {
		this.superproto.constructor.call(this, opts);
		this._documentEdit = this.getChildByName('documentEdit');
		this._documentEdit.subscribe('documentChanged', this._onDocumentChanged.bind(this));
	}, FirControl, {
		_onSubscribe: function() {
			this._elems('addDocBtn').on('click', this._onAddDocBtn_click.bind(this));
			this._elems('linkList').on('click', this._onLinkEditBtn_click.bind(this));
		},
		_onUnsubscribe: function() {
			this._elems('addDocBtn').off('click');
			this._elems('linkList').off('click');
		},
		_onAddDocBtn_click: function() {
			this._documentEdit.setNum(null); // Нужно сбрасывать номер
			this._documentEdit.openDialog();
		},
		_onLinkEditBtn_click: function(ev) {
			var
				el = $(ev.target).closest(this._elemClass('linkEditBtn')),
				self = this;
			if( !el || !el.length ) {
				return;
			}
			this._documentEdit.setNum(el.data('documentNum'));
			this._documentEdit.openDialog();
		},
		_onDocumentChanged: function() {
			location.reload();
		}
	});
});