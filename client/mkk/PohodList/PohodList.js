define('mkk/PohodList/PohodList', [
	'fir/controls/FirControl',
	'mkk/PohodList/PartyInfo/PartyInfo',
	'mkk/PohodList/Navigation/Navigation',
	'css!mkk/PohodList/PohodList'
], function(FirControl) {
	__extends(PohodList, FirControl);

	function PohodList(opts) {
		FirControl.call(this, opts);

		this._elems("tableContentBody")
			.on("click", this.onShowPartyBtn_click.bind(this));
		this._partyInfo = this.getChildInstanceByName('partyInfo');
	}
	return __mixinProto(PohodList, {
		onShowPartyBtn_click: function(ev) {
			var
				el = $(ev.target).closest(this._elemClass('showPartyBtn')),
				self = this;
			if( !el || !el.length ) {
				return;
			}

			var pohodNum = parseInt(el.data("pohodNum"), 10)
			if( !isNaN(pohodNum)) {
				this._partyInfo.openDialog({num: pohodNum});
			}
		}
	});
});