define('mkk/Helpers/ConfirmDialog/ConfirmDialog', [
	'fir/controls/FirControl'
], function (FirControl) {
return FirClass(
	function ConfirmDialog(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('yesBtn').on('click', this._onSomeBtn_click.bind(this, 'yes'));
			this._elems('noBtn').on('click', this._onSomeBtn_click.bind(this, 'no'));
			this._elems('cancelBtn').on('click', this._onSomeBtn_click.bind(this, 'cancel'));
		});
		this._unsubscr(function() {
			this._elems('yesBtn').off('click');
			this._elems('noBtn').off('click');
			this._elems('cancelBtn').off('click');
		});
	}, FirControl, {
		_onSomeBtn_click: function(cmd) {
			this._notify('onExecuted', cmd);
			this.destroy();
		}
	});
});