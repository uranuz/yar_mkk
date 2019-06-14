define('mkk/Pohod/List/Navigation/Navigation', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'css!mkk/Pohod/List/Navigation/Navigation'
], function(FirControl, helpers) {
return FirClass(
	function PohodListNavigation(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('searchBtn').on('click', this._onSearch_start.bind(this));
			helpers.doOnEnter(this._elems('pohodRegionField'), this._onSearch_start.bind(this));
			if( this._elems('printModeBtn').length ) {
				this._elems('printModeBtn').on('click', this._onPrintBtnClick.bind(this));
			}
		});
		this._unsubscr(function() {
			this._elems('printModeBtn').off();
			this._elems('searchBtn').off();
			this._elems('pohodRegionField').off('keyup');
		});
	}, FirControl, {
		/** Нажатие на кнопку печати */
		_onPrintBtnClick: function () {
			this._elems('isForPrintField').val("on");
			this._notify('onPrintBtnClick');
		},

		/** При старте поиска (при нажатии на кнопку поиска, либо нажатии на Enter в поисковой строке) */
		_onSearch_start: function() {
			this._notify('onSearchStart');
		},

		getFilter: function() {
			var params = {};
			params['pohodRegion'] = this._elems('pohodRegionField').val();
			this._fetchDateFilters(params);
			this._fetchEnumFilters(params);
			params['withFiles'] = this._elems('withFilesFlag').prop('checked');
			params['withDataCheck'] = this._elems('withDataCheckFlag').prop('checked');
			if( this._elems('isForPrintField').length ) {
				params['isForPrint'] = this._elems('isForPrintField').val() === 'on';
			}

			return params;
		},
		_fetchDateFilters: function(params) {
			var dtFields = [
				'beginRangeHead',
				'beginRangeTail',
				'endRangeHead',
				'endRangeTail'
			];
			for( var i = 0; i < dtFields.length; ++i ) {
				var
					dtField = dtFields[i],
					dtControl = this.getChildByName(dtField + 'Field');
				if( dtControl == null ) {
					continue;
				}
				params[dtField + '__year'] = dtControl.getYear();
				params[dtField + '__month'] = dtControl.getMonth();
				params[dtField + '__day'] = dtControl.getDay();
			}
			return params;
		},
		_fetchEnumFilters: function(params) {
			for( var i = 0; i < this._enumFields.length; ++i ) {
				var
					field = this._enumFields[i],
					control = this.getChildByName(field.num);
				params[field.num] = control.getSelectedKeys();
			}
			return params;
		},
		_getPaging: function() {
			return this.getChildByName(this.instanceName() + 'Paging');
		}
	}
);
});