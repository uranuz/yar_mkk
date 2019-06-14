define('mkk/Right/Rule/Edit/Edit', [
	'fir/controls/FirControl',
	'css!mkk/Right/Rule/Edit/Edit'
], function (FirControl) {
return FirClass(
	function RightRuleEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('saveBtn').on('click', this._onSaveBtn_click.bind(this));
			//this._elems('addRuleBtn').on('click', this._onSearch_start.bind(this));
		});
		this._unsubscr(function() {
			this._elems('saveBtn').off('click');
			//this._elems('addRuleBtn').off();
		});
		this.subscribe('onAfterLoad', this._onResultLoad);
	}, FirControl, {
		_getQueryParams: function(areaName) {
			if( areaName === 'Results' ) {
				return {
					record: {
						name: this._elems('nameField').val(),
						num: parseInt(this._elems('numField').val(), 10) || null
					}
				};
			}
		},

		_onSaveBtn_click: function() {
			this._reloadControl('Results');
		},

		_onResultLoad: function(ev, areaName) {
			if( areaName === 'Results' ) {
				this._elems('editForm').hide();
			}
		}
	}
);
});
