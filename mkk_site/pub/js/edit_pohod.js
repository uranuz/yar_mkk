mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	var
		pohod = mkk_site.edit_pohod;
	
	mkk_site.pohod_chef_edit.blockInit();
	mkk_site.pohod_party_edit.blockInit();

	$("#add_more_extra_file_links_btn")
	.on( "click", pohod.onAddMoreExtraFileLinks_BtnClick );

	$("#pohod_submit_btn")
	.on( "click", function(){
		pohod.saveListOfExtraFileLinks();
		$("#edit_pohod_form").submit();
	});
	
	$("#pohod_delete_btn")
	.on( "click", function(){
	   $( "#dialog" ).dialog();	
	});
	
	$("#delete_confirm_btn")
	.on( "click", pohod.onDeleteConfirm_BtnClick );
	
	pohod.loadListOfExtraFileLinks();
} );

//Редактирование руководителя и зам. руководителя похода
mkk_site.pohod_chef_edit = {

	//Инициализация блока редактирования руководителя и зам. руководителя похода
	blockInit: function()
	{	var
			pohod_chef_edit = mkk_site.pohod_chef_edit,
			blockChef = $(".b-pohod_chef_edit"),
			blockAltChef = $(".b-pohod_alt_chef_edit");

		blockChef.filter(".e-open_dlg_btn")
		.on( "click", {isAltChef: false}, pohod_chef_edit.onOpenChefEditDlg_BtnClick );

		blockAltChef.filter(".e-open_dlg_btn")
		.on( "click", {isAltChef: true}, pohod_chef_edit.onOpenChefEditDlg_BtnClick );

		//Тык по кнопке удаления зам. руководителя похода
		blockAltChef.filter(".e-delete_btn")
		.on( "click", function() {
			blockAltChef.filter(".e-tourist_key_inp").val("null");
			blockAltChef.filter(".e-open_dlg_btn").val("Редактировать");
			blockAltChef.filter(".e-dlg").dialog("destroy");
		});

		blockChef.filter(".e-search_btn")
		.on( "click",
			{ "isAltChef": false },
			pohod_chef_edit.onSearchChefCandidates_BtnClick
		);

		blockAltChef.filter(".e-search_btn")
		.on( "click",
			{ "isAltChef": true },
			pohod_chef_edit.onSearchChefCandidates_BtnClick
		);
	},
	
	//"Тык" по кнопке выбора руководителя или зама похода
	onSelectChef_BtnClick: function(event) {
		var
			pohod = mkk_site.pohod_chef_edit,
			isAltChef = event.data.isAltChef,
			block = $( isAltChef ? ".b-pohod_alt_chef_edit"  : ".b-pohod_chef_edit" );
			rec = event.data.record,
			dbKeyInp = block.filter(".e-tourist_key_inp"),
			openDlgBtn = block.filter(".e-open_dlg_btn");

		dbKeyInp.val( rec.get("num") );

		if( !pohod.participantsRS )
		{	pohod.participantsRS = new webtank.datctrl.RecordSet();
			pohod.participantsRS._fmt = rec._fmt;
		}

		if( !pohod.participantsRS.hasKey( rec.getKey() ) )
			pohod.participantsRS.append( rec );

		openDlgBtn.text( mkk_site.edit_pohod.getTouristInfoString(rec) );

		mkk_site.pohod_party_edit.renderParticipantsList();

		block.filter(".e-dlg").dialog("destroy");
	},

	//"Тык" по кнопке поиска кандидатов на руководство похода
	onSearchChefCandidates_BtnClick: function(event) {
		var
			pohod = mkk_site.pohod_chef_edit,
			isAltChef = event.data.isAltChef,
			blockClassName = ( isAltChef ? "b-pohod_alt_chef_edit"  : "b-pohod_chef_edit" ),
			block = $("." + blockClassName),
			messageDiv = block.filter(".e-search_message"),
			filterInput = block.filter(".e-search_filter");

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
						class: blockClassName + " e-search_results"
					});

				rs = webtank.datctrl.fromJSON(json);

				rs.rewind();

				while( rec = rs.next() )
				{	(function(record) {
						var
							recordDiv = $("<div>", {
								class: blockClassName + " e-select_btn"
							})
							.on( "click",
								{ "record": record, "isAltChef": isAltChef },
								pohod.onSelectChef_BtnClick
							),
							button = $("<div>", {
								class: blockClassName + " e-select_icon"
							})
							.appendTo(recordDiv),
							recordLink = $("<a>", {
								href: "#_NOLink",
								text: mkk_site.edit_pohod.getTouristInfoString(record)
							})
							.appendTo(recordDiv);

						recordDiv.appendTo(searchResultsDiv);
					})(rec);
				}

				block.filter(".e-search_results").replaceWith(searchResultsDiv); //Замена в DOM
			}
		});
	},

	//Тык по кнопке открытия окна выбора руководителя или зама
	onOpenChefEditDlg_BtnClick: function(event)
	{	var
			pohod = mkk_site.pohod_chef_edit,
			isAltChef = event.data.isAltChef,
			block = $( isAltChef ? ".b-pohod_alt_chef_edit" : ".b-pohod_chef_edit" ),
			rec;

		block.filter(".e-dlg").dialog({modal: true, minWidth: 400});
	},
	
};

mkk_site.pohod_party_edit = {
	participantsRS: null, //RecordSet с участниками похода
	
	selTouristsRS: null, //RecordSet с выбранными в поиске туристами

	//Инциализация блока редактирования списка участников
	blockInit: function()
	{
		var
			block = $(".b-pohod_party_edit"),
			pohod_party_edit = mkk_site.pohod_party_edit;

		block.filter(".e-search_btn")
		.on( "click", pohod_party_edit.onSearchTourists_BtnClick );

		block.filter(".e-accept_btn")
		.on( "click", pohod_party_edit.onSaveSelectedParticipants_BtnCLick );

		block.filter(".e-open_dlg_btn")
		.on( "click", pohod_party_edit.onOpenParticipantsEditWindow_BtnClick );

		//Загрузка списка участников похода с сервера
		pohod_party_edit.loadPohodParticipantsList();
	},

	//Метод образует разметку с информацией о выбранном туристе
	renderSelectedTourist: function(rec)
	{	var
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			recordDiv = $("<div>", {
				class: "b-pohod_party_edit e-tourist_deselect_btn"
			})
			.on( "click", rec, pohod.onDeselectTourist_BtnClick ),
			deselectBtn = $("<div>", {
				class: "b-pohod_party_edit e-tourist_deselect_icon"
			})
			.appendTo(recordDiv),
			recordLink = $("<a>", {
				href: "#_NOLink",
				text: mkk_site.edit_pohod.getTouristInfoString(rec)
			})
			.appendTo(recordDiv);
		
		return recordDiv;
	},
	
	//Выводит список участников похода из participantsRS в главное окно
	renderParticipantsList: function()
	{	var 
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			touristKeys = "",
			touristsList = block.filter(".e-tourists_list"),
			rec;

		touristsList.empty();
		
		pohod.participantsRS.rewind();
		while( rec = pohod.participantsRS.next() )
		{	touristKeys += ( touristKeys.length ? "," : "" ) + rec.getKey();
			$("<div>", {
				text: mkk_site.edit_pohod.getTouristInfoString(rec)
			})
			.appendTo(touristsList);
		}
		
		block.filter(".e-tourist_keys_inp").val(touristKeys);
	},
	
	//Загрузка списка участников похода
	loadPohodParticipantsList: function()
	{	var 
			doc = window.document,
			pohod = mkk_site.pohod_party_edit,
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
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			recordDiv,
			deselectBtn;
		
		if( !pohod.selTouristsRS )
		{	pohod.selTouristsRS = new webtank.datctrl.RecordSet();
			pohod.selTouristsRS._fmt = rec._fmt;
		}
		
		if( pohod.selTouristsRS.hasKey( rec.getKey() ) )
		{	block.filter(".e-select_message").html(
				"Турист <b>" + mkk_site.edit_pohod.getTouristInfoString(rec)
				+ "</b> уже находится в списке выбранных туристов"
			);
		}
		else
		{	pohod.selTouristsRS.append(rec);
			pohod.renderSelectedTourist(rec)
			.appendTo( block.filter(".e-selected_tourists") );
		}
	},
	
	//Обработчик отмены выбора записи
	onDeselectTourist_BtnClick: function(event) {
		var 
			rec = event.data,
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			recordDiv = $(this),
			touristSelectDiv = block.filter(".e-selected_tourists");
		
		pohod.selTouristsRS.remove( rec.getKey() );
		recordDiv.remove();
	},
	
	//Обработчик тыка по кнопке сохранения списка выбранных участников
	onSaveSelectedParticipants_BtnCLick: function() {
		var 
			block = $(".b-pohod_party_edit"),
			pohod = mkk_site.pohod_party_edit;
		
		pohod.participantsRS = webtank.deepCopy(pohod.selTouristsRS);
		pohod.renderParticipantsList();

		block.filter(".e-dlg").dialog("destroy");
	},
	
	//Тык по кнопке поиска туристов
	onSearchTourists_BtnClick: function(event) {
		var
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			messageDiv = block.filter(".e-select_message"),
			filterInput = block.filter(".e-search_filter");
		
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
						class: "b-pohod_party_edit e-found_tourists"
					});
				
				rs = webtank.datctrl.fromJSON(json);
				
				rs.rewind();
				
				while( rec = rs.next() )
				{	(function(record) {
						var
							button,
							recordDiv = $("<div>", {
								class: "b-pohod_party_edit e-tourist_select_btn"
							})
							.on( "click", record, pohod.onSelectTourist_BtnClick),
							button = $("<div>", {
									class: "b-pohod_party_edit e-tourist_select_icon"
							})
							.appendTo(recordDiv),
							recordLink = $("<a>", {
								href: "#_NOLink",
								text: mkk_site.edit_pohod.getTouristInfoString(record)
							}).appendTo(recordDiv);


						
						recordDiv.appendTo(searchResultsDiv);
					})(rec);
				}
				
				block.filter(".e-found_tourists").replaceWith(searchResultsDiv); //Замена в DOM
				block.filter(".e-found_tourists_panel").show();
				block.filter(".e-selected_tourists_panel").css("width", "50%");
			}
		});
	},
	
	//Тык по кнопке открытия окна редактирования списка участников
	onOpenParticipantsEditWindow_BtnClick: function() {
		var 
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			rec;
			
		//Очистка окна списка туристов перед заполнением
		block.filter(".e-selected_tourists").empty();
		
		if( pohod.participantsRS )
		{	//Создаем копию набора записей
			pohod.selTouristsRS = webtank.deepCopy(pohod.participantsRS);
			
			pohod.selTouristsRS.rewind();
			while( rec = pohod.selTouristsRS.next() )
			{	pohod.renderSelectedTourist(rec)
				.appendTo( block.filter(".e-selected_tourists") );
			}
		}

		block.filter(".e-dlg").dialog({"modal": true, minWidth: 500});
	}
};

mkk_site.edit_pohod = {
	
	//Возвращает строку описания туриста по записи
	getTouristInfoString: function(rec) {
		return " " + rec.get("family_name") + " " + rec.get("given_name") + " " 
			+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
	},

	///Работа со списком ссылок на дополнительные ресурсы
	//Размер одной "порции" полей ввода ссылок на доп. материалы
	extraFileLinksInputPortion: 5,
	//"Тык" по кнопке "Добавить ещё" (имеется в виду ссылок)
	onAddMoreExtraFileLinks_BtnClick: function()
	{	var
			pohod = mkk_site.edit_pohod,
			linkListDiv = $("#link_list_div"),
			inputPortion = pohod.extraFileLinksInputPortion,
			i = 0;

		for( ; i < inputPortion; i++ )
			pohod.renderInputsForExtraFileLink([]).appendTo( linkListDiv.children("table") );
	},

	//Создает элементы для ввода ссылки с описанием на доп. материалы
	renderInputsForExtraFileLink: function(data)
	{	var
			newTr = $("<tr>"),
			leftTd = $("<td>").appendTo(newTr),
			rightTd = $("<td>").appendTo(newTr),
			linkInput = $( "<input>", { type: "text" } ).appendTo(leftTd),
			commentInput = $( "<input>", { type: "text" } ).appendTo(rightTd);

		if( data )
		{	linkInput.val( data[0] || "" );
			commentInput.val( data[1] || "" );
		}

		return newTr;
	},

	//Отображает список ссылок на доп. материалы
	renderListOfExtraFileLinks: function(linkList)
	{	var
			pohod = mkk_site.edit_pohod,
			linkListDiv = $("#link_list_div"),
			newTable = $("<table>").append(
				$("<thead>").append(
					$("<tr>").append( $("<th>Ссылка</th>") ).append( $("<th>Название (комментарий)</th>") )
				)
			),
			inputPortion = pohod.extraFileLinksInputPortion,
			linkList = linkList ? linkList : [],
			inputCount = inputPortion - ( linkList.length - 1 ) % inputPortion,
			i = 0;
		
		for( ; i < inputCount; i++ )
			pohod.renderInputsForExtraFileLink( linkList[i] ).appendTo(newTable);
		
		linkListDiv.children("table").replaceWith(newTable);
	},

	//Загрузка списка ссылок на доп. материалы с сервера
	loadListOfExtraFileLinks: function()
	{	var
			getParams = webtank.parseGetParams(),
			pohodKey = parseInt(getParams["key"], 10);
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.списокСсылокНаДопМатериалы",
			params: { "pohodKey": pohodKey },
			success: mkk_site.edit_pohod.renderListOfExtraFileLinks
		});
	},

	//Сохранение списка ссылок на доп. материалы
	saveListOfExtraFileLinks: function()
	{	var
			pohod = mkk_site.edit_pohod,
			linkListDiv = $("#link_list_div"),
			tableRows = linkListDiv.children("table").children("tbody").children("tr"),
			extraFileLinksInput = $("#extra_file_links"),
			currInputs,
			link,
			comment,
			data = [],
			i = 0;

		for( ; i < tableRows.length; i++ )
		{
			currInputs = $(tableRows[i]).children("td").children("input");
			
			link = $(currInputs[0]).val();
			comment = $(currInputs[1]).val();

			if( $.trim(link).length && $.trim(link).length )
				data.push( [ link, comment ] );
		}

		extraFileLinksInput.val( JSON.stringify(data) );
	},

	jQueryUITest: function()
	{	var
			testDiv = $("<div>Здравствуй, Вася!!!</div>").appendTo("body");
		
		testDiv.dialog();
		testDiv.addClass("testClass");
	},
	
	//Обработчик тыка по кнопке подтверждения удаления похода
	onDeleteConfirm_BtnClick: function() {
		var
			getParams = webtank.parseGetParams(),
			pohodKey = parseInt(getParams["key"], 10);
		
		if( $("#delete_confirm_inp").val() === "удалить" )
		{
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.удалитьПоход",
				params: { "pohodKey": pohodKey }
			});
			document.location.replace("/dyn/show_pohod");
		}
		else
		{	$("#delete_confirm_inp").val("Не подтверждено!!!")
		}
	}

};
