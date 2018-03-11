define('mkk/UserSettings/UserSettings', [
	'fir/controls/FirControl',
	'fir/network/json_rpc'
], function(
	FirControl, json_rpc
) {
	__extends(UserSettings, FirControl);

	function UserSettings(opts) {
		FirControl.call(this, opts);
		this._oldPasswordField = this._elems('oldPasswordField');
		this._newPasswordField = this._elems('newPasswordField');
		this._repeatPasswordField = this._elems('repeatPasswordField');
		this._saveBtn = this._elems('saveBtn');
		this._emptyPasswordDlg = this._elems('emptyPasswordDlg');
		this._mismatchPasswordDlg = this._elems('mismatchPasswordDlg');

		this._elems('initPohodHistory').on('click', this.initPohodHistory.bind(this));
		this._elems('initTouristHistory').on('click', this.initTouristHistory.bind(this));
	}

	return __mixinProto(UserSettings, {
		_subscribeInternal: function() {
			this._saveBtn.on('click', this._onSaveBtn_click.bind(this));
		},
		_unsubscibeInternal: function() {
			this._saveBtn.off('click');
		},
		_onSaveBtn_click: function(ev) {
			var
				oldPassword = this._oldPasswordField.val(),
				newPassword = this._newPasswordField.val(),
				repeatPassword = this._repeatPasswordField.val();
			if( !oldPassword || !newPassword || !repeatPassword ) {
				ev.preventDefault();
				this._emptyPasswordDlg.dialog({
					modal: true,
					width: 200
				});
				return; // Показываем лишь один диалог за раз
			}
			if( newPassword !== repeatPassword ) {
				ev.preventDefault();
				this._mismatchPasswordDlg.dialog({
					modal: true,
					width: 200
				});
			}
		},
		initTouristHistory: function() {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "tourist.initHistoryData",
				params: null
			});
		},
		initPohodHistory: function() {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "pohod.initHistoryData",
				params: null
			});
		}
	});
});