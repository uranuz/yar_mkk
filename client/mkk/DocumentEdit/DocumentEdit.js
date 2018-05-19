define('mkk/DocumentEdit/DocumentEdit', [
	'fir/controls/FirControl',
	'mkk/Helpers/FilteredUpdateableDialog',
	'css!mkk/DocumentEdit/DocumentEdit'
], function (FirControl, FilteredUpdateableDialog) {
	__extends(DocumentEdit, FirControl);

	function DocumentEdit(opts) {
		FirControl.call(this, opts);
		this._filter = {};
		this._firstLoad = true;
		this.setDialogOptions({
			modal: true,
			minWidth: 500,
			width: 850,
			close: this._onDialogClose.bind(this)
		});
		this.setAllowedFilterParams([
			'num', 'name', 'link', 'action'
		]);
		this._updateControlState(opts);
	}
	return __mixinProto(DocumentEdit, [FilteredUpdateableDialog, {
		_subscribeInternal: function() {
			this._saveBtn.on('click', this._onSaveBtn_click.bind(this));
			this._elems('continueBtn').on('click', this._onDialogClose.bind(this));
		},
		_unsubscribeInternal: function() {
			this._saveBtn.off('click');
		},
		_updateControlState: function(opts) {
			this._docForm = this._elems('docForm');
			this._saveBtn = this._elems('saveBtn');
			this._isResultStep = opts.__scopeName__ === 'Results';
		},
		_getRequestURI: function() {
			return '/dyn/document/edit';
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
		},
		_onDialogClose: function() {
			if( this._isResultStep ) {
				this._notify('documentChanged');
			}
		}
	}]);
});