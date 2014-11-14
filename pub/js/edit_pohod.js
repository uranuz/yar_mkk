mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	//Инициализаци блоков на странице
	mkk_site.pohod_chef_edit = new PohodChefEdit();
	mkk_site.pohod_party_edit = new PohodPartyEdit();
	mkk_site.pohod_chef_edit = new PohodChefEdit();
	mkk_site.edit_pohod = new EditPohod();
} );

//Редактирование руководителя и зам. руководителя похода
PohodChefEdit = (function() {
	//Инициализация блока редактирования руководителя и зам. руководителя похода
	function PohodChefEdit()
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
			blockAltChef.filter(".e-open_dlg_btn").text("Редактировать");
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
	}
	
	//"Тык" по кнопке выбора руководителя или зама похода
	PohodChefEdit.prototype.onSelectChef_BtnClick = function(event) {
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
	};

	//"Тык" по кнопке поиска кандидатов на руководство похода
	PohodChefEdit.prototype.onSearchChefCandidates_BtnClick = function(event) {
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
	};

	//Тык по кнопке открытия окна выбора руководителя или зама
	PohodChefEdit.prototype.onOpenChefEditDlg_BtnClick = function(event)
	{	var
			pohod = mkk_site.pohod_chef_edit,
			isAltChef = event.data.isAltChef,
			block = $( isAltChef ? ".b-pohod_alt_chef_edit" : ".b-pohod_chef_edit" ),
			rec;

		block.filter(".e-dlg").dialog({modal: true, minWidth: 400});
	};
	
})();

PohodPartyEdit = (function() {
	//Инциализация блока редактирования списка участников
	function PohodPartyEdit()
	{
		var
			block = $(".b-pohod_party_edit"),
			pohod_party_edit = mkk_site.pohod_party_edit;
			
		this.participantsRS = null; //RecordSet с участниками похода
		this.selTouristsRS = null; //RecordSet с выбранными в поиске туристами
		this.page = 0;

		block.filter(".e-search_btn")
		.on( "click", pohod_party_edit.onSearchTourists_BtnClick );

		block.filter(".e-accept_btn")
		.on( "click", pohod_party_edit.onSaveSelectedParticipants_BtnCLick );

		block.filter(".e-open_dlg_btn")
		.on( "click", pohod_party_edit.onOpenParticipantsEditWindow_BtnClick );
		
		block.filter(".e-go_selected_btn")
		.on( "click", pohod_party_edit.onGoSelected_BtnClick );
		
		block.filter(".e-go_next_btn")
		.on( "click", pohod_party_edit.onGoNext_BtnClick );
		
		block.filter(".e-go_prev_btn")
		.on( "click", pohod_party_edit.onGoPrev_BtnClick );

		//Загрузка списка участников похода с сервера
		pohod_party_edit.loadPohodParticipantsList();
	}

	//Метод образует разметку с информацией о выбранном туристе
	PohodPartyEdit.prototype.renderSelectedTourist = function(rec)
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
	};
	
	//Выводит список участников похода из participantsRS в главное окно
	PohodPartyEdit.prototype.renderParticipantsList = function()
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
	};
	
	//Загрузка списка участников похода
	PohodPartyEdit.prototype.loadPohodParticipantsList = function()
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
	};
	
	//Обработчик добавления найденной записи о туристе
	PohodPartyEdit.prototype.onSelectTourist_BtnClick = function(event) {
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
	};
	
	//Обработчик отмены выбора записи
	PohodPartyEdit.prototype.onDeselectTourist_BtnClick = function(event) {
		var 
			rec = event.data,
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			recordDiv = $(this),
			touristSelectDiv = block.filter(".e-selected_tourists");
		
		pohod.selTouristsRS.remove( rec.getKey() );
		recordDiv.remove();
	};
	
	//Обработчик тыка по кнопке сохранения списка выбранных участников
	onSaveSelectedParticipants_BtnCLick: function() {
		var 
			block = $(".b-pohod_party_edit"),
			pohod = mkk_site.pohod_party_edit;
		
		pohod.participantsRS = webtank.deepCopy(pohod.selTouristsRS);
		pohod.renderParticipantsList();

		block.filter(".e-dlg").dialog("destroy");
			
	};

	//---Блок поиска участников----------
	
	// Тык по кнопке поиска туристов 
	PohodPartyEdit.prototype.onSearchTourists_BtnClick = function() {
		var
		   pohod = mkk_site.pohod_party_edit,//Переменные
			block = $(".b-pohod_party_edit");
			
		  	block.filter(".e-page_selected").val(1) ;	
			
			pohod.onSearchTourists();//Переход к действию по кнопке Искать
				
	};
	
	
	// Тык по кнопке Перехода на нужную страницу 
	PohodPartyEdit.prototype.onGoSelected_BtnClick = function() {
		var
		   pohod = mkk_site.pohod_party_edit,//Переменные
			block = $(".b-pohod_party_edit"),
			selected_page_value=block.filter(".e-page_selected").val(),			
			selected_page_obg=block.filter(".e-page_selected");
			
		  	// ограничения значений страницы в окошечке	
		if(selected_page_value<1) 	block.filter(".e-page_selected").val(1);		 
		if(selected_page_value>pohod.page) 	block.filter(".e-page_selected").val(pohod.page);
			
			
		pohod.onSearchTourists();//Переход к действию 
	};
	
	//Тык по кнопке Предыдущая страница
	PohodPartyEdit.prototype.onGoPrev_BtnClick = function() {
		var
	   	pohod = mkk_site.pohod_party_edit,//Переменные
			block = $(".b-pohod_party_edit"),
			selected_page_value=block.filter(".e-page_selected").val();

		block.filter(".e-page_selected").val(+selected_page_value - 1) ;
		pohod.onGoSelected_BtnClick();//Переход к действию 
	};
	
	//Тык по кнопке Следующая страница
	PohodPartyEdit.prototype.onGoNext_BtnClick = function() {
		var
		   pohod = mkk_site.pohod_party_edit,//Переменные
			block = $(".b-pohod_party_edit"),
			selected_page_value=block.filter(".e-page_selected").val();

		block.filter(".e-page_selected").val(+selected_page_value + 1) ;	
		pohod.onGoSelected_BtnClick();//Переход к действию 
	};
	
	
	// переход от Тыка по  любой из  выше описанных кнопок  
	PohodPartyEdit.prototype.onSearchTourists = function(event) {
		var
			pohod = mkk_site.pohod_party_edit,
			block = $(".b-pohod_party_edit"),
			messageDiv = block.filter(".e-select_message"),
			family_filterInput = block.filter(".e-family_filter"),
			name_filterInput = block.filter(".e-name_filter"),
			patronymic_filterInput = block.filter(".e-patronymic_filter"),
			year_filterInput = block.filter(".e-year_filter");			
			region_filterInput = block.filter(".e-region_filter");
			city_filterInput = block.filter(".e-city_filter");
			street_filterInput = block.filter(".e-street_filter");
			page_selectedInput = block.filter(".e-page_selected");
			selected_page_value=block.filter(".e-page_selected").val(),//значение			
			selected_submit=block.filter(".e-go_selected_btn"),			
			prev_submit=block.filter(".e-go_prev_btn"),
			next_submit=block.filter(".e-go_next_btn");
			 
		if( family_filterInput.val().length < 2 )
		{	messageDiv.text("Минимальная длина фильтра для поиска равна 2 символам");
			return;
		}
		else
		{	messageDiv.empty();
		}
		
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.getTouristList",
			params: { 
				"фамилия": family_filterInput.val(), 
				"имя": name_filterInput.val(),
				"отчество": patronymic_filterInput.val(),
				"год_рождения": year_filterInput.val(),
				 "регион":region_filterInput.val() ,  
				 "город": city_filterInput.val(),  
				 "улица":street_filterInput.val(),
				 "страница":page_selectedInput.val()
			},
			success: function(json)// исполняется по приходу результата
			{
				var
					rec,
					searchResultsDiv = $("<div>", {
						class: "b-pohod_party_edit e-found_tourists"
					}),
					col_str = json.recordCount;// Количество строк

				rs = webtank.datctrl.fromJSON(json.rs);
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
				block.filter(".e-dlg").dialog({"modal": true, minWidth: 1000});
				
				var f1 = block.filter(".e-label");
				if( col_str >0 )
					pohod.page = Math.ceil(col_str/3) ;
				else
					pohod.page = 0;
				// ограничения кнопки перейти	при наличи одой и менее страниц кнопка не видима
				if(pohod.page<=1) 
					selected_submit.css('visibility', 'hidden');
				else 
					selected_submit.css('visibility', 'visible');
								
				//  состояние кнопки предыдущая 
				if(selected_page_value<2 || pohod.page<=1 )
							prev_submit.css('visibility', 'hidden')
					else  prev_submit.css('visibility', 'visible');
				
				// состояние кнопки далее
				if(selected_page_value>=pohod.page || pohod.page<=1 ) 
							next_submit.css('visibility', 'hidden')
					else   next_submit.css('visibility', 'visible');
										
				
				
				var label;
				if(col_str<1)
				{	label = "Соответствия не найдено";
				  // selected_submit.css('visibility', 'hidden');	
					//prev_submit.css('visibility', 'hidden');
				//	next_submit.css('visibility', 'hidden');
				}					
				else
					label = "Страница "+selected_page_value +
					" из  " + pohod.page  + ". Туристов " + col_str+".";

				f1.html(label);
			}
		});// конец webtank.json_rpc.invoke
	};
	
	//Тык по кнопке открытия окна редактирования списка участников
	PohodPartyEdit.prototype.onOpenParticipantsEditWindow_BtnClick = function() {
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
	};
})();

EditPohod = (function() {
	//Инициализация блока редактирования похода
	function EditPohod()
	{	var
			block = $(".b-edit_pohod");

		block.filter(".e-open_delete_dlg_btn")
		.on( "click", function(){
			block.filter(".e-delete_dlg").dialog();
		});

		block.filter(".e-delete_confirm_btn")
		.on( "click", mkk_site.edit_pohod.onDeleteConfirm_BtnClick );

		block.filter(".e-add_more_extra_file_links_btn")
		.on( "click", mkk_site.edit_pohod.onAddMoreExtraFileLinks_BtnClick );

		block.filter(".e-submit_btn")
		.on( "click", function(){
			mkk_site.edit_pohod.saveListOfExtraFileLinks();
			block.filter(".e-edit_pohod_form").submit();
		});

		mkk_site.edit_pohod.loadListOfExtraFileLinks();
	}
	
	//Возвращает строку описания туриста по записи
	EditPohod.prototype.getTouristInfoString = function(rec) {
		return " " + rec.get("family_name") + " " + rec.get("given_name") + " " 
			+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
	};

	///Работа со списком ссылок на дополнительные ресурсы
	//Размер одной "порции" полей ввода ссылок на доп. материалы
	extraFileLinksInputPortion: 5,
	//"Тык" по кнопке "Добавить ещё" (имеется в виду ссылок)
	EditPohod.prototype.onAddMoreExtraFileLinks_BtnClick = function()
	{	var
			block = $(".b-edit_pohod"),
			pohod = mkk_site.edit_pohod,
			inputPortion = pohod.extraFileLinksInputPortion,
			i = 0;

		for( ; i < inputPortion; i++ )
			pohod.renderInputsForExtraFileLink([]).appendTo( block.filter(".e-link_list_table") );
	};

	//Создает элементы для ввода ссылки с описанием на доп. материалы
	EditPohod.prototype.renderInputsForExtraFileLink = function(data)
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
	};

	//Отображает список ссылок на доп. материалы
	EditPohod.prototype.renderListOfExtraFileLinks = function(linkList)
	{	var
			block = $(".b-edit_pohod"),
			pohod = mkk_site.edit_pohod,
			newTable = $( "<table>", {class: "b-edit_pohod e-link_list_table"} )
			.append(
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
		
		block.filter(".e-link_list_table").replaceWith(newTable);
	};

	//Загрузка списка ссылок на доп. материалы с сервера
	EditPohod.prototype.loadListOfExtraFileLinks = function()
	{	var
			getParams = webtank.parseGetParams(),
			pohodKey = parseInt(getParams["key"], 10);
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.списокСсылокНаДопМатериалы",
			params: { "pohodKey": pohodKey },
			success: mkk_site.edit_pohod.renderListOfExtraFileLinks
		});
	};

	//Сохранение списка ссылок на доп. материалы
	EditPohod.prototype.saveListOfExtraFileLinks = function()
	{	var
			block = $(".b-edit_pohod"),
			pohod = mkk_site.edit_pohod,
			tableRows = block.filter(".e-link_list_table").children("tbody").children("tr"),
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

		block.filter(".e-extra_file_links_inp").val( JSON.stringify(data) );
	};

	//Обработчик тыка по кнопке подтверждения удаления похода
	EditPohod.prototype.onDeleteConfirm_BtnClick = function() {
		var
			block = $(".b-edit_pohod"),
			getParams = webtank.parseGetParams(),
			pohodKey = parseInt(getParams["key"], 10);
		
		if( block.filter(".e-delete_confirm_inp").val() === "удалить" )
		{
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.удалитьПоход",
				params: { "pohodKey": pohodKey }
			});
			document.location.replace("/dyn/show_pohod");
		}
		else
		{	block.filter(".e-delete_confirm_inp").val("Не подтверждено!!!")
		}
	}
})();
