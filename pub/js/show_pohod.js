var mkk_site = mkk_site || {
	version: "0.0"
};

mkk_site.PohodParticipantsListDialog = (function(_super) {
	__extends(PohodParticipantsListDialog, _super);

	function PohodParticipantsListDialog( opts ) {
		opts = opts || {};
		opts._controlTypeName = 'PohodParticipantsListDialog';

		_super.call(this, opts);

	}

	return __mixinProto( PohodParticipantsListDialog, {
		open: function() {

		},
		onClose: function() {

		}
	});
})(webtank.ITEMControl);

mkk_site.ShowPohod = (function(_super) {
	__extends(ShowPohod, _super);
	
	function ShowPohod(opts)
	{
		opts = opts || {};
		opts.controlTypeName = 'ShowPohod';
		_super.call(this, arguments);
		
		var self = this;
		$(".show_participants_btn").click(function(ev){ self.showParticipants($(this), ev); });
	}
	return __mixinProto(ShowPohod, {
		showParticipants: function(el)
		{	var
				self = this,
				input = el.children("input"),
				pohodNum = parseInt(input.val(), 10);

			webtank.json_rpc.invoke({
				uri: "/dyn/jsonrpc/",  //Адрес для отправки 
				method: "mkk_site.show_pohod.participantsList", //Название удалённого метода для вызова в виде строки
				params: {"pohodNum": pohodNum} , //Параметры вызова удалённого метода
				success: function(data) { self.okno(data); } //Обработчик успешного вызова удалённого метода
			});
		},
		
		okno: function(data)
		{
			var 
				//Создает слой со списком участников
				touristList = $('<div id="gruppa" title="Участники похода"></div>');
				//Создает фоновый прозрачный слой для перехвата щелчка мыши
				//blackoutDiv = document.createElement("div");
			
			//blackoutDiv.setAttribute("class", "tourist_list_blackout");
			
			//Добавление обработчика события щелчка по фоновому слою
			//$(blackoutDiv).on( "click", function() {
				//touristList.remove(); //Уничтожение div'а со списком туристов
				//$(blackoutDiv).remove();  //Уничтожение div'a для затемнения
			//});
			
			//Вставка текста в слой списка участников
			touristList.html(data);
			
			//Добавление слоев к телу документа
			touristList.appendTo("body");
			//$(blackoutDiv).appendTo("body");
			touristList.dialog( { modal: true } );
		}
	});
})(webtank.ITEMControl);

//Инициализация страницы
$(window.document).ready( function() {
	mkk_site.show_pohod = new mkk_site.ShowPohod({

	});
});