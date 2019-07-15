define('mkk/Pohod/Edit/Chief/AddToParty/AddToParty', [
	'fir/controls/FirControl'
], function (FirControl) {
'use strict';
return FirClass(
	function ChiefAddToParty(opts) {
		this.superproto.constructor.call(this, opts);

		this._acceptBtn = this._elems("acceptBtn");
		this._cancelBtn = this._elems("cancelBtn");

		this._subscr(function() {
			this._acceptBtn.on('click', this._onAcceptBtn_click.bind(this));
			this._cancelBtn.on('click', this._onCancelBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._acceptBtn.off('click');
			this._cancelBtn.off('click');
		});
	}, FirControl, {
		_onAcceptBtn_click: function() {
			this._notify('ok');
			this.destroy();
		},
		_onCancelBtn_click: function() {
			this._notify('cancel');
			this.destroy();
		}
	});
});