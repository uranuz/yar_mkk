define('mkk/Pohod/Edit/Chief/AddToParty/AddToParty', [
	'fir/controls/FirControl'
], function (FirControl) {
return FirClass(
	function ChiefAddToParty(opts) {
		this.superproto.constructor.call(this, opts);

		this._acceptBtn = this._elems("acceptBtn");
		this._cancelBtn = this._elems("cancelBtn");
		this._touristsCountField = this._elems("touristsCount");

		this._acceptBtn.on('click', this._onAcceptBtn_click.bind(this));
		this._cancelBtn.on('click', this._onCancelBtn_click.bind(this));
	}, FirControl, {
		open: function(touristsCount) {
			this._touristsCountField.text( (touristsCount || '[не задано]') + ' человек');
			this._getContainer().dialog({
				modal: true,
				width: 400,
				close: this._onDialog_close.bind(this)
			});
		},
		_onAcceptBtn_click: function() {
			this._notify('ok');
		},
		_onCancelBtn_click: function() {
			this._getContainer().dialog('close');
		},
		_onDialog_close: function() {
			this._notify('cancel');
		}
	});
});