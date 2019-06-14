define('mkk/Document/Edit/Edit', [
	'fir/controls/FirControl'
], function (FirControl) {
return FirClass(
	function DocumentEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function(ev) {
			this._elems('saveBtn').on('click', this._onSaveBtn_click.bind(this));
		});
		this._unsubscr(function(ev) {
			this._elems('saveBtn').off('click');
		});
		this.subscribe('onAfterLoad', this._onDocumentEdit_load);
	}, FirControl, {
		_getRPCMethod: function(areaName) {
			if( areaName === 'EditResults' ) {
				return 'document.edit';
			}
		},
		_getQueryParams: function(areaName) {
			if( areaName === 'EditResults' ) {
				return {
					record: this.getRecord()
				};
			}
		},
		_getViewParams: function(areaName) {
			if( areaName === 'EditResults' ) {
				return {
					whatObject: 'документ',
					num: parseInt(this._elems('num').val(), 10) || null
				};
			}
		},
		getRecord: function() {
			return {
				num: parseInt(this._elems('num').val(), 10) || null,
				name: this._elems('name').val(),
				link: this._elems('link').val()
			};
		},
		_onSaveBtn_click: function() {
			this._reloadControl('EditResults');
		},
		_onDocumentEdit_load: function(ev, areaName) {
			if( areaName === 'EditResults' ) {
				this._elems('docForm').hide();
			}
		}
	});
});