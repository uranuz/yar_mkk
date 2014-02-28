mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	var
		pohod = mkk_site.edit_pohod;
	
	//Инициализация событий на странице
	$("#pohod_chef_edit_btn")
	.on( "click", pohod.onOpenChefSelectionWindow_BtnClick );
	
	$("#pohod_alt_chef_edit_btn")
	.on( "click", pohod.onOpenChefSelectionWindow_BtnClick );
	
	$("#pohod_participants_edit_btn")
	.on( "click", pohod.onOpenParticipantsEditWindow_BtnClick );
	
	//Загрузка списка участников похода с сервера
	pohod.loadPohodParticipantsList();
} );

mkk_site.edit_pohod = {
	participantsRS: null, //RecordSet с участниками похода
	
	selTouristsRS: null, //RecordSet с выбранными в поиске туристами
	
	//Метод образует разметку с информацией о выбранном туристе
	renderSelectedTourist: function(rec)
	{	var
			pohod = mkk_site.edit_pohod,
			recordDiv = $("<div>", {
				text: pohod.getTouristInfoString(rec)
			}),
			deselectBtn = $("<div>", {
				class: "tourist_deselect_btn"
			})
			.on( "click", rec, pohod.onDeselectTourist_BtnClick )
			.prependTo(recordDiv);
		
		return recordDiv;
	},
	
	//Выводит список участников похода из participantsRS в главное окно
	renderParticipantsList: function()
	{	var 
			pohod = mkk_site.edit_pohod,
			unitNeimValue = "",
			unitDiv = $("#unit_div"),
			rec;

		unitDiv.empty();
		
		pohod.participantsRS.rewind();
		while( rec = pohod.participantsRS.next() )
		{	unitNeimValue += ( unitNeimValue.length ? "," : "" ) + rec.getKey();
			$("<div>", {
				text: pohod.getTouristInfoString(rec)
			})
			.appendTo(unitDiv);
		}
		
		$("#unit_neim").val(unitNeimValue);
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
			success: function(json) {
				pohod.participantsRS = webtank.datctrl.fromJSON(json);
				
				pohod.renderParticipantsList();
			}
		});
	},
	
	//Обработчик добавления найденной записи о туристе
	onSelectTourist_BtnClick: function(event) {
		var 
			rec = event.data, //Добавляемая запись
			pohod = mkk_site.edit_pohod,
			recordDiv,
			deselectBtn;
		
		if( !pohod.selTouristsRS )
		{	pohod.selTouristsRS = new webtank.datctrl.RecordSet();
			pohod.selTouristsRS._fmt = rec._fmt;
		}
		
		if( pohod.selTouristsRS.hasKey( rec.getKey() ) )
		{	$(".tourist_select_message").html(
				"Турист <b>" + pohod.getTouristInfoString(rec)
				+ "</b> уже находится в списке выбранных туристов"
			);
		}
		else
		{	pohod.selTouristsRS.append(rec);
			pohod.renderSelectedTourist(rec)
			.appendTo(".selected_tourists");
		}
	},
	
	//Обработчик отмены выбора записи
	onDeselectTourist_BtnClick: function(event) {
		var 
			rec = event.data,
			pohod = mkk_site.edit_pohod,
			removeBtn = $(this),
			recordDiv = removeBtn.parent(),
			touristSelectDiv = $(".selected_tourists");
		
		pohod.selTouristsRS.remove( rec.getKey() );
		recordDiv.remove();
	},
	
	//Обработчик тыка по кнопке сохранения списка выбранных участников
	onSaveSelectedParticipants_BtnCLick: function() {
		var 
			searchWindow = $(".tourist_selection_window"),
			windowContent = $(searchWindow).children(".modal_window_content"),
			pohod = mkk_site.edit_pohod;
		
		pohod.participantsRS = webtank.deepCopy(pohod.selTouristsRS);
		
		if( !pohod.participantsRS )
		{	$(searchWindow).remove();
			$(".modal_window_blackout").remove();
			return;
		}
		
		pohod.renderParticipantsList();
		
		$(searchWindow).remove();
		$(".modal_window_blackout").remove();
	},
	
	//Тык по кнопке поиска туристов
	onSearchTourists_BtnClick: function(event) {
		var
			pohod = mkk_site.edit_pohod,
			messageDiv = $(".tourist_select_message"),
			filterInput = $(".tourist_search_filter");
		
		if( filterInput.val().length < 3 )
		{	messageDiv.text("Минимальная длина фильтра для поиска равна 3 символам");
			return;
		}
		else
		{	messageDiv.empty();
		}
		
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.getTouristList",
			params: { "фамилия": filterInput.val() },
			success: function(json) {
				var
					rec,
					searchResultsDiv = $("<div>", {
						class: "found_tourists"
					});
				
				rs = webtank.datctrl.fromJSON(json);
				
				rs.rewind();
				
				while( rec = rs.next() )
				{	(function(record) {
						var
							button,
							recordDiv = $("<div>", {
								text: pohod.getTouristInfoString(record)
							});

						button = $("<div>", {
							class: "tourist_select_btn"
						})
						.on( "click", record, 
							  pohod.onSelectTourist_BtnClick
						).prependTo(recordDiv);
						
						recordDiv.appendTo(searchResultsDiv);
					})(rec);
				}
				
				$(".found_tourists").replaceWith(searchResultsDiv); //Замена в DOM
			}
		});
	},
	
	//Тык по кнопке открытия окна редактирования списка участников
	onOpenParticipantsEditWindow_BtnClick: function() {
		var 
			pohod = mkk_site.edit_pohod,
			rec,
			searchWindow = webtank.wui.createModalWindow(),
			windowContent = $(searchWindow).children(".modal_window_content"),
			splitViewTable = $('<table><tr style="vertical-align: top;"><td></td><td></td></tr></table>'),
			splitViewTableRow = splitViewTable.children("tbody").children("tr")
			splitViewLeft = splitViewTableRow.children("td")[0],
			splitViewRight = splitViewTableRow.children("td")[1],
			foundTouristsDiv = $("<div>", {
				class: "found_tourists"
			}),
			touristSearchInp = $("<input>", {
				type: "text",
				class: "tourist_search_filter"
			}),
			touristSearchButton = $("<input>", {
				type: "button",
				value: "Искать!"
			}),
			okButton = $("<input>", {
				type: "button",
				value: "     OK     "
			}),
			touristSelectDiv = $("<div>", {
				class: "selected_tourists"
			}),
			messageDiv = $("<div>", {
				class: "tourist_select_message"
			});
			
		if( pohod.participantsRS )
		{	//Создаем копию набора записей
			pohod.selTouristsRS = webtank.deepCopy(pohod.participantsRS);
			
			pohod.selTouristsRS.rewind();
			while( rec = pohod.selTouristsRS.next() )
			{	pohod.renderSelectedTourist(rec)
				.appendTo(touristSelectDiv);
			}
		}
		
		$(touristSearchButton)
		.on( "click", pohod.onSearchTourists_BtnClick ); 
		
		$(okButton).on( "click", pohod.onSaveSelectedParticipants_BtnCLick );

		$(searchWindow).addClass("tourist_selection_window");
		
		$(windowContent)
		.append(touristSearchInp)
		.append(touristSearchButton)
		.append(okButton)
		.append(messageDiv);
		
		$(splitViewLeft).append("<b>Участники похода</b>").append(touristSelectDiv);
		$(splitViewRight).append("<b>Поиск туристов</b>").append(foundTouristsDiv);
		$(splitViewTable).appendTo(windowContent);
	},
	
	//Возвращает строку описания туриста по записи
	getTouristInfoString: function(rec) {
		return " " + rec.get("family_name") + " " + rec.get("given_name") + " " 
			+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
	},
	
	//"Тык" по кнопке выбора руководителя или зама похода
	onSelectChef_BtnClick: function(event) {
		var
			pohod = mkk_site.edit_pohod,
			filterInput = $(".pohod_chef_search_filter"),
			searchResultContainer = $(".pohod_chef_search_results"),
			isAltChef = event.data.isAltChef,
			rec = event.data.record,
			chefInput = isAltChef ? $("#alt_chef") : $("#chef_grupp"),
			chefEditBtn = isAltChef ? $("#pohod_alt_chef_edit_btn") : $("#pohod_chef_edit_btn");
		
		chefInput.val( rec.get("num") );
		
		if( !pohod.participantsRS )
		{	pohod.participantsRS = new webtank.datctrl.RecordSet();
			pohod.participantsRS._fmt = rec._fmt;
		}

		if( !pohod.participantsRS.hasKey( rec.getKey() ) )
			pohod.participantsRS.append( rec );
		
		chefEditBtn.text( pohod.getTouristInfoString(rec) );

		pohod.renderParticipantsList();
		
		$(".chef_selection_window").remove();
		$(".modal_window_blackout").remove();
	},
	
	//"Тык" по кнопке поиска кандидатов на руководство похода
	onSearchChefCandidates_BtnClick: function(event) {
		var
			pohod = mkk_site.edit_pohod,
			messageDiv = $(".pohod_chef_search_message"),
			filterInput = $(".pohod_chef_search_filter");
		
		if( filterInput.val().length < 3 )
		{	messageDiv.text("Минимальная длина фильтра для поиска равна 3 символам");
			return;
		}
		else
		{	messageDiv.text("");
		}
		
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.getTouristList",
			params: { "фамилия": filterInput.val() },
			success: function(json) {
				var
					rec,
					searchResultsDiv = $("<div>", {
						class: "pohod_chef_search_results"
					});
				
				rs = webtank.datctrl.fromJSON(json);
				
				rs.rewind();
				
				while( rec = rs.next() )
				{	(function(record) {
						var
							button,
							recordDiv = $("<div>", {
								text: pohod.getTouristInfoString(record)
							});

						button = $("<div>", {
							class: "pohod_chef_select_btn"
						})
						.on( "click", 
							  { "record": record, "isAltChef": event.data.isAltChef }, 
							  pohod.onSelectChef_BtnClick
						).prependTo(recordDiv);
						
						recordDiv.appendTo(searchResultsDiv);
					})(rec);
				}
				
				$(".pohod_chef_search_results").replaceWith(searchResultsDiv); //Замена в DOM
			}
		});
	},
	
	//Тык по кнопке открытия окна выбора руководителя или зама
	onOpenChefSelectionWindow_BtnClick: function()
	{	var 
			pohod = mkk_site.edit_pohod,
			rec,
			modalWindow = webtank.wui.createModalWindow(),
			windowContent = $(modalWindow).children(".modal_window_content"),
			filterInput = $('<input>', {
				type: 'text',
				class: "pohod_chef_search_filter"
			}),
			searchBtn = $('<input>', {
				type: 'button',
				value: "Искать!"
			}),
			searchResultsDiv = $('<div>', {
				class: "pohod_chef_search_results"
			}),
			messageDiv = $("<div>", {
				class: "pohod_chef_search_message"
			})
			isAltChef =  this.id == "pohod_alt_chef_edit_btn";
		
		$(modalWindow).addClass("chef_selection_window");
		
		searchBtn.on( "click", 
			{ "isAltChef": isAltChef }, 
			pohod.onSearchChefCandidates_BtnClick 
		);
		
		$(windowContent)
		.append(filterInput)
		.append(searchBtn)
		.append(messageDiv)
		.append(searchResultsDiv);
	}

};
