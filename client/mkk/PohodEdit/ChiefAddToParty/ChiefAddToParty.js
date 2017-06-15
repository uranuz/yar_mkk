define('mkk/PohodEdit/ChiefAddToParty/ChiefAddToParty', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(ChiefAddToParty, FirControl);

	function ChiefAddToParty(opts)
	{
		FirControl.call(this, opts);

		this._acceptBtn = this._elems("acceptBtn");
		this._cancelBtn = this._elems("cancelBtn");
		this._touristsCountField = this._elems("touristsCount");

		this._acceptBtn.on('click', this.onAcceptBtn_click.bind(this));
		this._cancelBtn.on('click', this.onCancelBtn_click.bind(this));
	}

	return __mixinProto(ChiefAddToParty, {
		open: function(touristsCount) {
			this._touristsCountField.text( ( touristsCount || '[не задано]' ) + ' человек');
			this._container.dialog({
				modal: true,
				width: 400,
				close: this.onDialog_close.bind(this)
			});
		},
		onAcceptBtn_click: function() {
			$(this).trigger('ok');
		},
		onCancelBtn_click: function() {
			this._container.dialog('close');
		},
		onDialog_close: function() {
			$(this).trigger('cancel');
		}
	});
});