define('mkk/Pohod/List/List', [
	'fir/controls/FirControl',
	'mkk/Pohod/List/PartyInfo/PartyInfo',
	'mkk/Pohod/List/Navigation/Navigation',
	'css!mkk/Pohod/List/List'
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