define('mkk/Document/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/Helpers/DialogMixin'
], function (FirControl, DialogMixin) {
return FirClass(
	function DocumentEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this.setDialogOptions({
			modal: true,
			minWidth: 500,
			width: 850,
			close: this._onDialogClose.bind(this)
		});
		this._updateControlState(opts);
	}, FirControl, [DialogMixin], {
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
			return (areaName === 'Results'? 'post': 'get');
		},
		_getRequestURI: function(areaName) {
			return (areaName === 'Results'? '/dyn/document/edit/results': '/dyn/document/edit');
		},
		_getRPCMethod: function(areaName) {
			return 'document.read';
		},
		_getQueryParams: function(areaName) {
			if( areaName === 'Results' ) {
				return {record: this.getFilter()};
			} else{
				return {num: this._num};
			}
		},
		getFilter: function() {
			var
				params = {},
				formData = this._docForm.serializeArray();
			// Получаем данные из формы и запихиваем в фильтр
			if( formData ) {
				for( var i = 0; i < formData.length; ++i ) {
					params[formData[i].name] = formData[i].value;
				}
			}

			if( params.num == null ) {
				params.num = this._num;
			}

			return params;
		},
		setNum: function(num) {
			this._num = num;
		},
		_onSaveBtn_click: function() {
			this._reloadControl('Results');
		},
		_onDialogClose: function() {
			if( this._isResultStep ) {
				this._notify('documentChanged');
			}
		}
	});
});