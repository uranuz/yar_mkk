define('mkk/Document/List/List', [
	'fir/controls/FirControl',
	'css!mkk/Document/List/List'
], function (FirControl) {
return FirClass(
	function DocumentList(opts) {
		this.superproto.constructor.call(this, opts);

		this._subscr(function() {
			this._elems('addDocBtn').on('click', this._onAddDocBtn_click.bind(this));
			this._elems('linkList').on('click', this._onLinkEditBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('addDocBtn').off('click');
			this._elems('linkList').off('click');
		});
		this.subscribe('onAfterLoad', function() {
			this._documentEdit = this.getChildByName('documentEdit');
			this._documentEdit.subscribe('documentChanged', this._onDocumentChanged.bind(this));
		});
	}, FirControl, {
		_onAddDocBtn_click: function() {
			this._documentEdit.setNum(null); // Нужно сбрасывать номер
			this._documentEdit.openDialog();
		},
		_onLinkEditBtn_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('linkEditBtn'));
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