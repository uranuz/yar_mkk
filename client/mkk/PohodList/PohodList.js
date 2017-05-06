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

			json_rpc.invoke({
				uri: "/dyn/jsonrpc/", //Адрес для отправки 
				method: "mkk_site.show_pohod.participantsList", //Название удалённого метода для вызова в виде строки
				params: { "pohodNum": +el.data("pohodNum") }, //Параметры вызова удалённого метода
				success: this.showParticipantsDialog.bind(this) //Обработчик успешного вызова удалённого метода
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

//Инициализация страницы
$(window.document).ready(function() {
	var
		filterCtrlNames = [
			'pohod_filter_vid',
			'pohod_filter_ks',
			'pohod_filter_prepar',
			'pohod_filter_stat'
		],
		filterCtrlName;
	mkk_site.show_pohod_table = new mkk_site.ShowPohodTable({
		controlName: "show_pohod_table"
	});
	mkk_site.show_pohod = new mkk_site.PohodNavigation({
		controlName: "pohod_navigation"
	});

	for (var i = 0; i < filterCtrlNames.length; ++i) {
		filterCtrlName = filterCtrlNames[i];
		mkk_site[filterCtrlName] = new webtank.ui.CheckBoxList({
			controlName: filterCtrlName
		});
	}
});