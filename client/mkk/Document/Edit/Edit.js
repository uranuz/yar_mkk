define('mkk/Document/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/Helpers/FilteredUpdateableDialog'
], function (FirControl, FilteredUpdateableDialog) {
return FirClass(
	function DocumentEdit(opts) {
		this.superproto.constructor.call(this, opts);
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
	}, FirControl, [FilteredUpdateableDialog], {
		_onSubscribe: function() {
			this._saveBtn.on('click', this._onSaveBtn_click.bind(this));
			this._elems('continueBtn').on('click', this._onDialogClose.bind(this));
		},
		_onUnsubscribe: function() {
			this._saveBtn.off('click');
		},
		_updateControlState: function(opts) {
			this._docForm = this._elems('docForm');
			this._saveBtn = this._elems('saveBtn');
			this._isResultStep = opts.__scopeName__ === 'Results';
		},
		_getHTTPMethod: function(areaName) {
			return (areaName === 'results'? 'post': 'get');
		},
		_getRequestURI: function(areaName) {
			return (areaName === 'results'? '/dyn/document/edit/results': '/dyn/document/edit');
		},
		_getRPCMethod: function(areaName) {
			return 'document.read';
		},
		_onSaveBtn_click: function() {
			var formData = this._docForm.serializeArray();
			// Получаем данные из формы и запихиваем в фильтр
			if( formData ) {
				for( var i = 0; i < formData.length; ++i ) {
					this._filter[formData[i].name] = formData[i].value;
				}
			}
			this._reloadControl('results');
		},
		_onDialogClose: function() {
			if( this._isResultStep ) {
				this._notify('documentChanged');
			}
		}
	});
});