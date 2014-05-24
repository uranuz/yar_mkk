mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	$(".show_participants_btn").on( "click", mkk_site.show_pohod.showParticipants );
	
} );

mkk_site.show_pohod = {
	showParticipants: function(event)
	{	var
			input = $(this).children("input"),
			pohodNum = parseInt(input.val(),10);
		webtank.json_rpc.invoke({
			uri: "/dyn/jsonrpc/",  //Адрес для отправки 
		
		method:"mkk_site.show_pohod.participantsList", //Название удалённого метода для вызова в виде строки
		params:{"pohodNum":pohodNum} , //Параметры вызова удалённого метода
		success: mkk_site.show_pohod.okno //Обработчик успешного вызова удалённого метода	
			
		})
		
		
	},
	okno: function(result)
	{
		var 
			//Создает слой со списком участников
			touristList = $("<div id='gruppa' ></div>"),
			//Создает фоновый прозрачный слой для перехвата щелчка мыши
			blackoutDiv = document.createElement("div");
		
		blackoutDiv.setAttribute("class", "tourist_list_blackout");
		
		//Добавление обработчика события щелчка по фоновому слою
		$(blackoutDiv).on( "click", function() {
			touristList.remove(); //Уничтожение div'а со списком туристов
			$(blackoutDiv).remove();  //Уничтожение div'a для затемнения
		} );
		
		//Вставка текста в слой списка участников
		touristList.html(result);
		
		//Добавление слоев к телу документа
		touristList.appendTo("body");
		$(blackoutDiv).appendTo("body");
	}
};
