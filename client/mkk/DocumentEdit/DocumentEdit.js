define('mkk/DocumentEdit/DocumentEdit', [
	'fir/controls/FirControl',
	'css!mkk/DocumentEdit/DocumentEdit'
], function (FirControl, DatctrlHelpers) {
	__extends(DocumentEdit, FirControl);
	var allowedFilterParams = [
		'key', 'name', 'link', 'action'
	];

	function DocumentEdit(opts) {
		FirControl.call(this, opts);
		this._filter = {};
		this._updateControlState(opts);
		this._firstLoad = true;
	}
	return __mixinProto(DocumentEdit, {
		_subscribeInternal: function() {
			this._saveBtn.on('click', this._onSaveBtn_click.bind(this));
		},
		_unsubscribeInternal: function() {
			this._saveBtn.off('click');
		},
		_updateControlState: function(opts) {
			this._docForm = this._elems('docForm');
			this._saveBtn = this._elems('saveBtn');
		},
		openDialog: function(num) {
			this.setFilter({
				key: num
			});
			this._reloadControl();
		},
		setFilter: function(filter) {
			this._filter = filter;
		},
		_getRequestURI: function() {
			return '/dyn/document/edit';
		},
		_getQueryParams: function(areaName) {
			var params = [];
			if( this._filter ) {
				for( var i = 0; i < allowedFilterParams.length; ++i ) {
					if( this._filter[ allowedFilterParams[i] ] ) {
						params.push(allowedFilterParams[i] + '=' + this._filter[ allowedFilterParams[i] ]);
					}
				}
			}
			params.push('generalTemplate=no');
			params.push('instanceName=documentEdit');
			return params.join('&');
		},
		_onAfterLoad: function() {
			var self = this;
			FirControl.prototype._onAfterLoad.call(this, arguments);
			if( !this._firstLoad ) {
				self._container.dialog({
					modal: true,
					minWidth: 500,
					width: 850
				});
			} else {
				this._firstLoad = false;
			}
			this._notify('onDocumentLoaded');
		},
		_onSaveBtn_click: function() {
			var	formData = this._docForm.serializeArray();
			// Получаем данные из формы и запихиваем в фильтр
			if( formData ) {
				for( var i = 0; i < formData.length; ++i ) {
					this._filter[formData[i].name] = formData[i].value;
				}
			}
			this._filter.action = 'write';
			this._reloadControl();
		}
	});
});