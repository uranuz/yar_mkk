mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	$(".show_participants_btn").on( "click", mkk_site.show_tourist.showParticipants );
	
} );

mkk_site.show_tourist = {
	showParticipants: function(event)
	{	var
			input = $(this).children("input"),
			pohodNum = parseInt(input.val(),10);
		webtank.json_rpc.invoke({
			uri: "/dyn/jsonrpc",  //Адрес для отправки 
		
		method:"mkk_site.show_pohod.participantsList", //Название удалённого метода для вызова в виде строки
		params:{"pohodNum":pohodNum} , //Параметры вызова удалённого метода
		success: mkk_site.show_tourist.okno //Обработчик успешного вызова удалённого метода	
			
		})
		
		
	},
	okno: function(result)
	{
		var 
			touristList = $("<div>");
		
		touristList.html(result);
		
		touristList.appendTo("body");
	}
};
