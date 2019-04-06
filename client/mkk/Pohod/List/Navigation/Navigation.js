define('mkk/Pohod/List/Navigation/Navigation', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'css!mkk/Pohod/List/Navigation/Navigation'
], function(FirControl) {
return FirClass(
	function PohodListNavigation(opts) {
		this.superproto.constructor.call(this, opts);

		this._elems().filter(".e-print_page_btn").on("click", this.onPrintPageBtnClick.bind(this));
		this._enumFields = opts.enumFields;
	}, FirControl, {
		onPrintPageBtnClick: function () {
			this._elems().filter(".e-for_print_input").val("on");
			this._elems().filter(".e-form")[0].submit();
		},

		getFilter: function() {
			var params = {};
			params['pohodRegion'] = this._elems('pohodRegionField').val();
			this._fetchDateFilters(params);
			this._fetchEnumFilters(params);
			params['withFiles'] = this._elems('withFilesFlag').prop('checked');
			params['withDataCheck'] = this._elems('withDataCheckFlag').prop('checked');

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
		}
	}
);
});