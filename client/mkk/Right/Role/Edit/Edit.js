define('mkk/Right/Role/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/Right/Role/Edit/Edit.scss'
], function (FirControl) {
return FirClass(
	function RightRoleEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('saveBtn').on('click', this._onSaveBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('saveBtn').off('click');
		});
	}, FirControl, {
		/** Обработчик нажатия по кнопке "Сохранить" */
		_onSaveBtn_click: function() {
			var lazyArea = this.getChildByName(this.instanceName() + 'ResultsArea');
			lazyArea.open({
				bodyParams: {
					record: this.getRecord()
				}
			}).then(function() {
				this._elems('editForm').hide();
			}.bind(this));
		},

		/** Возвращает данные записи из формы */
		getRecord: function() {
			return {
				name: this._elems('nameField').val(),
				num: parseInt(this._elems('numField').val(), 10) || null,
				description: this._elems('descriptionField').val()
			}
		}
	}
);
});
