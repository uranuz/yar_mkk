define('mkk/PohodList/PohodList', [
	'fir/controls/FirControl',
	'fir/network/json_rpc'
], function(FirControl, json_rpc) {
	__extends(PohodList, FirControl);

	function PohodList(opts) {
		opts = opts || {};
		opts.controlTypeName = 'PohodList';
		FirControl.call(this, opts);

		this._elems("show_participants_btn")
			.on("click", this.onParticipantsBtnClick.bind(this));
	}
	return __mixinProto(PohodList, {
		onParticipantsBtnClick: function(ev) {
			var
				el = $(ev.currentTarget);

			$.ajax('http://localhost/dyn/pohod/partyInfo?key=' + (+el.data("pohodNum")) , {
				success: this.showParticipantsDialog.bind(this)
			});
		},
		showParticipantsDialog: function(data) {
			var
				//Создаем контейнер для списка участников
				touristList = $('<div id="gruppa" title="Участники похода"></div>');

			//Вставка текста в слой списка участников
			touristList.html(data)
				.appendTo("body")
				.dialog({ modal: true, width: 450 });
		}
	});
});