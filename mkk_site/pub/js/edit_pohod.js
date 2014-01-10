mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	mkk_site.edit_pohod.loadPohodParticipantsList();
	
} );

mkk_site.edit_pohod = {
	participantsRS: null, //RecordSet с участниками похода
	
	selTouristsRS: null, //RecordSet с выбранными в поиске туристами
	
	renderTouristRecord: function(rec, onAppend, onRemove)
	{	var
			appendBtn,
			removeBtn,
			recordDiv = $("<div>", {
				text: rec.get("family_name") + " " + rec.get("given_name") + " " 
					+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
			});
		
		if( onAppend )
		{	appendBtn = $("<img>", {
				src: "/pub/img/icons/append_icon.png",
			})
			.on( "click", rec, onAppend )
			.appendTo(recordDiv);
		}
		
		if( onRemove )
		{	removeBtn = $("<img>", {
				src: "/pub/img/icons/remove_icon.png",
			})
			.on( "click", rec, onRemove )
			.appendTo(recordDiv);
		}
		
		return recordDiv;
	},
	
	//Загрузка списка участников похода
	loadPohodParticipantsList: function()
	{	var 
			doc = window.document,
			pohod = mkk_site.edit_pohod,
			getParams = webtank.parseGetParams(),
			pohodKey = parseInt(getParams["key"], 10);
		
		if( isNaN(pohodKey) )
			return;
			
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.списокУчастниковПохода",
			params: { "pohodKey": pohodKey },
			success: function(responseJSON) {
				var 
					unitNeimInput = $("#unit_neim")[0];
				
				unitNeimInput.value = "";
				
				pohod.participantsRS = webtank.datctrl.fromJSON(responseJSON);
				
				$("#unit_div").empty();
				
				pohod.participantsRS.rewind();
				while( rec = pohod.participantsRS.next() )
				{	pohod.renderTouristRecord(rec)
					.appendTo("#unit_div");
				}
			}
		});
	},
	
	//Обработчик добавления найденной записи о туристе
	selectTourist: function(event) {
		
		var 
			rec = event.data, //Добавляемая запись
			pohod = mkk_site.edit_pohod;
		
		if( !pohod.selTouristsRS )
		{	pohod.selTouristsRS = new webtank.datctrl.RecordSet();
			pohod.selTouristsRS._fmt = rec._fmt;
		}
		
		if( pohod.selTouristsRS.hasKey( rec.getKey() ) )
		{	$("#tourist_select_msg_div").html(
				"Турист <b>" + rec.get("family_name") + " " 
				+ rec.get("given_name") + " " + rec.get("patronymic")
				+ "</b> уже находится в списке выбранных туристов"
			);
		}
		else
		{	pohod.selTouristsRS.append(rec);
			pohod.renderTouristRecord(rec, null, pohod.deselectTourist)
			.appendTo("#tourist_select_div");
		}
	},
	
	//Обработчик отмены выбора записи
	deselectTourist: function(event) {
		var 
			rec = event.data,
			pohod = mkk_site.edit_pohod,
			removeBtn = $(this),
			recordDiv = removeBtn.parent(),
			touristSelectDiv = $("#tourist_select_div");
		
		pohod.selTouristsRS.remove( rec.getKey() );
		recordDiv.remove();
		//pohod.renderTouristRecord(rec, null, deselectTourist);
	},
	
	//Получение списка туристов для
	searchForTourist: function() {
		var
			pohod = mkk_site.edit_pohod;
			
		$("#tourist_search_div").empty();
			
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.getTouristList",
			params: { "фамилия": $("#tourist_search_inp").val() },
			success: function(responseJSON) {
				var
					rs = webtank.datctrl.fromJSON(responseJSON),
					rec,
					pohod = mkk_site.edit_pohod,
					touristSelectDiv = $("#tourist_select_div");
				
				rs.rewind();
				while( rec = rs.next() )
				{	pohod.renderTouristRecord(rec, pohod.selectTourist)
					.appendTo("#tourist_search_div");
				}
			}
		});
	},
	onTouristSelWinOkBtnCLick: function() {
		var 
			unitNeimInput = $("#unit_neim")[0],
			searchWindow = $("#tourist_select_window"),
			windowContent = $(searchWindow).children(".modal_window_content"),
			pohod = mkk_site.edit_pohod;
			
		$("#unit_div").empty();
		unitNeimInput.value = "";
		
		if( !pohod.participantsRS )
		{	$(searchWindow).remove();
			$(".modal_window_blackout").remove();
			return;
		}
		
		pohod.participantsRS = webtank.deepCopy(pohod.selTouristsRS);
		
		pohod.participantsRS.rewind();
		while( rec = pohod.participantsRS.next() )
		{	unitNeimInput.value += ( unitNeimInput.value.length ? "," : "" ) + rec.getKey();
			pohod.renderTouristRecord(rec)
			.appendTo("#unit_div");
		}
		
		$(searchWindow).remove();
		$(".modal_window_blackout").remove();
	},
	openParticipantsEditWindow: function() {
		var 
			pohod = mkk_site.edit_pohod,
			rec,
			searchWindow = webtank.wui.createModalWindow(),
			windowContent = $(searchWindow).children(".modal_window_content"),
			splitViewTable = $('<table><tr style="vertical-align: top;"><td></td><td></td></tr></table>'),
			splitViewTableRow = splitViewTable.children("tbody").children("tr")
			splitViewLeft = splitViewTableRow.children("td")[0],
			splitViewRight = splitViewTableRow.children("td")[1],
			touristSearchDiv = $("<div>", {
				id: "tourist_search_div"
			}),
			touristSearchInp = $("<input>", {
				type: "text",
				id: "tourist_search_inp"
			}),
			touristSearchButton = $("<input>", {
				type: "button",
				value: "Найти"
			}),
			okButton = $("<input>", {
				type: "button",
				value: "     OK     "
			}),
			touristSelectDiv = $("<div>", {
				id: "tourist_select_div"
			}),
			messageDiv = $("<div>", {
				id: "tourist_select_msg_div"
			});
			
		if( pohod.participantsRS )
		{	//Создаем копию набора записей
			pohod.selTouristsRS = webtank.deepCopy(pohod.participantsRS);
			
			pohod.selTouristsRS.rewind();
			while( rec = pohod.selTouristsRS.next() )
			{	pohod.renderTouristRecord(rec, null, pohod.deselectTourist)
				.appendTo(touristSelectDiv);
			}
		}
		
		$(touristSearchButton)
		.on( "click", mkk_site.edit_pohod.searchForTourist ); 
		
		//Подтверждение выбора группы
		$(okButton).on( "click", pohod.onTouristSelWinOkBtnCLick );
		
		searchWindow.id = "tourist_select_window";
		$(windowContent)
		.append(touristSearchInp)
		.append(touristSearchButton)
		.append(okButton)
		.append(messageDiv);
		
		$(splitViewLeft).append("<b>Участники похода</b>").append(touristSelectDiv);
		$(splitViewRight).append("<b>Поиск туристов</b>").append(touristSearchDiv);
		$(splitViewTable).appendTo(windowContent);
	}
};
