mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	mkk_site.edit_tourist = new EditTourist();
} );

EditTourist = (function(){
	function EditTourist()
	{
		
	}
	
	EditTourist.prototype.processSimilarTourists = function(table) {
		var
			doc = window.document,
			contentDiv = doc.getElementById("send_tourist_win_content"),
			similarTouristsDiv,
			forceInsertBtn,
			commentDiv;
			
			
		if( table === null )
		{	editTouristForm.submit();
			
		}
		else
		{	commentDiv = doc.createElement("div");
			commentDiv.innerHTML = 
			'В базе данных найдены похожие туристы. Возможно, добавляемый турист уже имеется в базе. '
			+ 'Если это так, можно перейти к его редактированию. Если новый турист ещё не существует, можно '
			+ 'продолжить добавление.';
			contentDiv.appendChild(commentDiv);
			
			forceInsertBtn = doc.createElement("input");
			forceInsertBtn.type = "button";
			forceInsertBtn.value = "Продолжить добавление";
			forceInsertBtn.onclick = function() {
				doc.getElementById("edit_tourist_form").submit();
			}
			contentDiv.appendChild(forceInsertBtn);
			
			similarTouristsDiv = doc.createElement("div");
			similarTouristsDiv.innerHTML = table;
			contentDiv.appendChild(similarTouristsDiv);
		}
	}
	
	EditTourist.prototype.sendButtonClick = function() {
		var 
		windowYPos = webtank.getScrollTop() + 50,
		touristSendWindow = webtank.wui.createModalWindow("Редактирование туриста", windowYPos),
		windowContent = $(touristSendWindow).children(".modal_window_content")[0],
		touristKey = NaN,
		doc = window.document
		editTouristForm = doc.getElementById("edit_tourist_form"),
		birthYearInp = doc.getElementById("birth_year"),
		birthYear = parseInt(birthYearInp.value, 10);
		
		
		
		if( isNaN(birthYear) )
			birthYear = null;
		
		windowContent.id = "send_tourist_win_content";
		
		try {
			touristKey = parseInt( webtank.parseGetParams().key );
		} catch(e) { touristKey = NaN; }
		
		if( isNaN(touristKey) )
		{	//Добавление нового
			
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_tourist.тестНаличияПохожегоТуриста",
				params: {
					"имя": doc.getElementById("given_name").value,
											"фамилия": doc.getElementById("family_name").value,
											"отчество": doc.getElementById("patronymic").value,
											"годРожд": birthYear
				},
				success: mkk_site.edit_tourist.processSimilarTourists
			});
		}
		else
		{	//Редактирование существующего
			editTouristForm.submit();
		}
	}
	
	return EditTourist;
})();