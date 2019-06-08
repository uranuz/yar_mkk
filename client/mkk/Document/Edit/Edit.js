define('mkk/Document/Edit/Edit', [
	'fir/controls/FirControl'
], function (FirControl) {
return FirClass(
	function DocumentEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function(ev) {
			this._saveBtn.on('click', this._onSaveBtn_click.bind(this));
			this._elems('continueBtn').on('click', this._onDialogClose.bind(this));
		});
		this._unsubscr(function(ev) {
			this._saveBtn.off('click');
		});
		this.subscribe('onAfterLoad', function(ev, opts) {
			this._docForm = this._elems('docForm');
			this._saveBtn = this._elems('saveBtn');
			this._isResultStep = opts.__scopeName__ === 'Results';
		});
	}, FirControl, {
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