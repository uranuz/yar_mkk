var mkk_site = mkk_site || {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	mkk_site.show_pohod = new ShowPohod();
} );

mkk_site.PohodParticipantsListDialog = (function(_super) {
	__extends(PohodParticipantsListDialog, _super);

	function PohodParticipantsListDialog( controlName ) {
		_super.call(this, arguments);

		var
			self = this;

		this._controlName = controlName;
		this._controlTypeName = 'PohodParticipantsListDialog';

	}

	return __mixinProto( PohodParticipantsListDialog, {
		open: function() {

		},
		onClose: function() {

		},
		getInstanceHTMLClass: function() {
			return 'i-' + this._controlName;
		},
		getControlName: function() {
			return this._controlName;
		},
		getControlTypeName: function() {
			return this._controlTypeName;
		}
	});
})(webtank.ITEMControl);

ShowPohod = (function(_super) {
	__extends(ShowPohod, _super);
	
	function ShowPohod ()
	{
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
				touristList = $("<div id='gruppa'></div>"),
				//Создает фоновый прозрачный слой для перехвата щелчка мыши
				blackoutDiv = document.createElement("div");
			
			blackoutDiv.setAttribute("class", "tourist_list_blackout");
			
			//Добавление обработчика события щелчка по фоновому слою
			$(blackoutDiv).on( "click", function() {
				touristList.remove(); //Уничтожение div'а со списком туристов
				$(blackoutDiv).remove();  //Уничтожение div'a для затемнения
			});
			
			//Вставка текста в слой списка участников
			touristList.html(data);
			
			//Добавление слоев к телу документа
			touristList.appendTo("body");
			$(blackoutDiv).appendTo("body");
		}
	});
})(webtank.ITEMControl);
