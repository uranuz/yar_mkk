define('mkk/Right/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/Right/Edit/Edit.scss'
], function (FirControl, json_rpc) {
return FirClass(
	function RightEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._roleField = this.getChildByName('roleField');
		this._ruleField = this.getChildByName('ruleField');
		this._objectField = this.getChildByName('objectField');
		this._subscr(function() {
			this._elems('saveBtn').on('click', this._onSaveBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('saveBtn').off('click');
		});
		this.subscribe('onAfterLoad', this._onResultLoad);
		this._addValidators();
	}, FirControl, {
		_updateRecord: function() {
			this._right.set({
				num: (parseInt(this._elems('numField').val(), 10) || null),
				accessKind: (this._elems('accessKindField').val() + ''),
				// undefined means that old values shall remain...
				roleNum: (this._roleField? this._roleField.getSelectedKey(): undefined),
				ruleNum: (this._ruleField? this._ruleField.getSelectedKey(): undefined),
				objectNum: (this._objectField? this._objectField.getSelectedKey(): undefined),
				inheritance: !!this._elems('inheritanceField').prop('checked')
			});
		},

		getRecord: function() {
			this._updateRecord();
			return this._right;
		},

		_onSaveBtn_click: function() {
			if( !this.getValidation().validate() ) {
				return;
			}

			var lazyArea = this.getChildByName(this.instanceName() + 'ResultsArea');
			lazyArea.open({
				bodyParams: {
					record: this.getRecord().toObject()
				}
			}).then(function() {
				this._elems('editForm').hide();
			}.bind(this));
		},

		getValidation: function() {
			return this.getChildByName(this.instanceName() + 'Validation');
		},

		_addValidators: function() {
			var vlds = [];
			this._addSelectorValidator(vlds, this._roleField);
			this._addSelectorValidator(vlds, this._ruleField);
			this._addSelectorValidator(vlds, this._objectField);

			this.getValidation().addValidators(vlds);
		},

		_addSelectorValidator: function(vlds, selField) {
			if( selField ) {
				vlds.push({
					control: selField,
					fn: this._testRecord.bind(this)
				})
			}
		},

		_testRecord: function(vld) {
			return vld.control.getSelectedKey() != null || 'Не заполнено обязательное поле';
		}
	}
);
});