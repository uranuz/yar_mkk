define('mkk/Right/Edit/Edit', [
	'fir/controls/FirControl',
	'css!mkk/Right/Edit/Edit'
], function (FirControl, json_rpc) {
return FirClass(
	function RightEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._roleField = this.getChildByName('roleField');
		this._ruleField = this.getChildByName('ruleField');
		this._subscr(function() {
			this._elems('saveBtn').on('click', this._onSaveBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('saveBtn').off('click');
		});
		this.subscribe('onAfterLoad', this._onResultLoad);
	}, FirControl, {
		_getQueryParams: function(areaName) {
			if( areaName === 'EditResults' ) {
				return {
					record: this.getRecord()
				};
			}
		},

		getRecord: function() {
			var
				roleRec = this._roleField.getRecord(),
				ruleRec = this._ruleField.getRecord();
			return {
				num: (parseInt(this._elems('numField').val(), 10) || null),
				accessKind: (this._elems('accessKindField').val() + ''),
				roleNum: (roleRec? roleRec.getKey(): null),
				ruleNum: (ruleRec? ruleRec.getKey(): null),
				inheritance: !!this._elems('inheritanceField').prop('checked')
			};
		},

		_getViewParams: function(areaName) {
			if( areaName === 'EditResults' ) {
				return {
					whatObject: 'правил',
					num: parseInt(this._elems('numField').val(), 10) || null
				};
			}
		},

		_onSaveBtn_click: function() {
			this._reloadControl('EditResults');
		},

		_onResultLoad: function(ev, areaName) {
			if( areaName === 'EditResults' ) {
				this._elems('editForm').hide();
			}
		}
	}
);
});