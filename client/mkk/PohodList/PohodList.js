define('mkk/PohodList/PohodList', [
	'fir/controls/FirControl',
	'fir/network/json_rpc',
	'css!mkk/PohodList/PohodList'
], function(FirControl, json_rpc) {
	__extends(PohodList, FirControl);

	function PohodList(opts) {
		opts = opts || {};
		FirControl.call(this, opts);

		this._elems("tableContentBody")
			.on("click", this.onShowPartyBtn_click.bind(this));
	}
	return __mixinProto(PohodList, {
		onShowPartyBtn_click: function(ev) {
			var
				el = $(ev.target).closest(this._elemClass('showPartyBtn')),
				self = this;
			if( !el && !el.length ) {
				return;
			}

			$.ajax('/dyn/pohod/partyInfo?key=' + (+el.data("pohodNum")) , {
				success: self.showPartyDialog.bind(self)
			});
		},
		showPartyDialog: function(data) {
			var
				//Создаем контейнер для списка участников
				touristList = $('<div id="gruppa" title="Участники похода"></div>');

			//Вставка текста в слой списка участников
			touristList.html(data)
				.appendTo("body")
				.dialog({ modal: true, width: 500 });
		}
	});
});