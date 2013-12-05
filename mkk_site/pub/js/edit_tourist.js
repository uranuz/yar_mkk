mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	
	
} );

mkk_site.edit_tourist = {
	processSimilarTourists: function(table)
	{	var
			doc = window.document,
			contentDiv = doc.getElementById("send_tourist_win_content");
		
		if( table === null )
		{	
			
		}
		else
		{	contentDiv.innerHTML = table;
			
		}
		
	},
	sendButtonClick: function() {
		var 
			touristSendWindow = webtank.wui.createModalWindow(),
			windowContent = $(touristSendWindow).children(".modal_window_content")[0],
			touristKey = NaN,
			doc = window.document
			editTouristForm = doc.getElementById("edit_tourist_form");
			
			windowContent.id = "send_tourist_win_content";
			
		try {
			touristKey = parseInt( webtank.parseGetParams().key );
		} catch(e) { touristKey = NaN; }
		
		if( isNaN(touristKey) )
		{	//Добавление нового
			
			webtank.json_rpc.invoke({
				uri: "/dyn/jsonrpc",
				method: "mkk_site.edit_tourist.тестНаличияПохожегоТуриста",
				params: {
					"имя": doc.getElementById("given_name").value,
					"фамилия": doc.getElementById("family_name").value,
					"отчество": doc.getElementById("patronymic").value,
					"годРожд": doc.getElementById("birth_year").value
				},
				success: mkk_site.edit_tourist.processSimilarTourists
			});
		}
		else
		{	//Редактирование существующего
			editTouristForm.submit();
		}
	},
	
};
