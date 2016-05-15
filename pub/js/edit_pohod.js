mkk_site = mkk_site || {
	version: "0.0"
};

mkk_site.utils = {
	//Возвращает строку описания туриста по записи
	getTouristInfoString: function(rec) {
		var 
			output = "",
			familyName = rec.get("family_name", ""),
			givenName = rec.get("given_name", ""),
			patronymic = rec.get("patronymic", ""),
			birthYear = "" + rec.get("birth_year", "");
		
		if( familyName.length )
			output += familyName;
		if( givenName.length )
			output += " " + givenName;
		if( patronymic.length )
			output += " " + patronymic;
		if( birthYear.length )
			output += ", " + birthYear + " г.р";
		return output;
	}
};

var getParams = webtank.parseGetParams();

//Инициализация страницы
$(window.document).ready( function() {
	//Инициализаци блоков на странице
	mkk_site.tourist_search = new TouristSearch();
	mkk_site.pohod_chef_edit = new PohodChefEdit({searchBlock: mkk_site.tourist_search});
	mkk_site.pohod_party_edit = new PohodPartyEdit({searchBlock: mkk_site.tourist_search});
	mkk_site.edit_pohod = new EditPohod({
		chefEditBlock: mkk_site.pohod_chef_edit,
		partyEditBlock: mkk_site.pohod_party_edit
	});
} );

//Блок поиска туристов
TouristSearch = (function(_super) {
	__extends(TouristSearch, _super);
	
	function TouristSearch()
	{
		_super.call(this);
		
		var self = this;
		
		this.elems = $(".b-tourist_search");
		this.resultsPanel = this.$el('.e-search_results_panel');

		this.$el(".e-search_btn").$on("click", self.onSearchTourists_BtnClick );
		this.$el(".e-go_selected_btn").$on("click", self.onGoSelected_BtnClick );
		this.$el(".e-go_next_btn").$on("click", self.onGoNext_BtnClick );
		this.$el(".e-go_prev_btn").$on("click", self.onGoPrev_BtnClick );
		
		this.$el(".e-found_tourists").$on("click", ".e-tourist_select_btn", function(ev, el) {
			var record = self.recordSet.getRecord($(el).data('id'))
			self.$trigger('itemSelect', [self, record]);
		});
		
		this.$el('.e-block').hide();
	}
	
	return __mixinProto(TouristSearch, {
		// Тык по кнопке поиска туристов 
		onSearchTourists_BtnClick: function() {
			this.$el(".e-page_selected").val(1);
			this.onSearchTourists(); //Переход к действию по кнопке Искать
		},
		
		// Тык по кнопке Перехода на нужную страницу 
		onGoSelected_BtnClick: function(ev, el) {
			var
				self = this,
				selected_page_value = this.$el(".e-page_selected").val(),
				selected_page_obg = this.$el(".e-page_selected");
			
			// ограничения значений страницы в окошечке	
			if( selected_page_value < 1 )
				this.$el(".e-page_selected").val(1); 
			if( selected_page_value > self.page ) 
				this.$el(".e-page_selected").val(self.page);
			
			this.onSearchTourists();//Переход к действию 
		},
		
		//Тык по кнопке Предыдущая страница
		onGoPrev_BtnClick: function(ev, el) {
			var
				selected_page_value = this.$el(".e-page_selected").val();

			this.$el(".e-page_selected").val( +selected_page_value - 1 );
			this.onGoSelected_BtnClick(el, ev);//Переход к действию 
		},
		
		//Тык по кнопке Следующая страница
		onGoNext_BtnClick: function(ev, el) {
			var
				selected_page_value = this.$el(".e-page_selected").val();
			this.$el(".e-page_selected").val( +selected_page_value + 1 );
			this.onGoSelected_BtnClick(el, ev);//Переход к действию 
		},

		// переход от Тыка по  любой из  выше описанных кнопок  
		onSearchTourists: function(event) {
			var
				self = this,
				messageDiv = this.$el(".e-select_message"),
				selected_page_value = this.$el(".e-page_selected").val();

	// 		if( family_filterInput.val().length < 2 )
	// 		{	messageDiv.text("Минимальная длина фильтра для поиска равна 2 символам");
	// 			return;
	// 		}
	// 		else
	// 		{	messageDiv.empty();
	// 		}

			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.getTouristList",
				params: { 
					"фамилия": this.$el(".e-family_filter").val(), 
					"имя": this.$el(".e-name_filter").val(),
					"отчество": this.$el(".e-patronymic_filter").val(),
					"год_рождения": this.$el(".e-year_filter").val(),
					"регион": this.$el(".e-region_filter").val() ,  
					"город": this.$el(".e-city_filter").val(),  
					"улица": this.$el(".e-street_filter").val(),
					"страница": this.$el(".e-page_selected").val()
				},
				success: function(json)// исполняется по приходу результата
				{
					var
						rec,
						searchResultsDiv = self.$el(".e-found_tourists"),
						summaryDiv = self.$el(".e-tourists_found_summary"),
						selected_submit = self.$el(".e-go_selected_btn"),
						prev_submit = self.$el(".e-go_prev_btn"),
						next_submit = self.$el(".e-go_next_btn"),
						navigBar = self.$el(".e-page_navigation_bar"),
						pageCountDiv = self.$el(".e-page_count"),
						col_str = json.recordCount;// Количество строк
						perPage = json.perPage || 10;
					
					self.recordSet = webtank.datctrl.fromJSON(json.rs);
					self.recordSet.rewind();
					
					searchResultsDiv.empty();
					while( rec = self.recordSet.next() )
						self.renderFoundTourist(rec).appendTo(searchResultsDiv);
					
					self.resultsPanel.show();

					if( col_str > 0 )
						self.page = Math.ceil(col_str/perPage);
					else
						self.page = 0;
					// ограничения кнопки перейти при наличи одой и менее страниц кнопка не видима
					if( self.page <= 1 ) 
						selected_submit.css('visibility', 'hidden');
					else 
						selected_submit.css('visibility', 'visible');
					
					//  состояние кнопки предыдущая 
					if( selected_page_value < 2 || self.page <= 1 )
						prev_submit.css('visibility', 'hidden');
					else 
						prev_submit.css('visibility', 'visible');

					// состояние кнопки далее
					if( selected_page_value >= self.page || self.page <= 1 ) 
						next_submit.css('visibility', 'hidden');
					else 
						next_submit.css('visibility', 'visible');

					if( col_str < 1 )
					{	summaryDiv.text("По данному запросу не найдено туристов");
						navigBar.hide();
					}
					else
					{
						summaryDiv.text("Найдено " + col_str + " туристов");
						pageCountDiv.text(self.page);
						navigBar.show();
					}
				}
			});// конец webtank.json_rpc.invoke
		},
		
		renderFoundTourist: function(record) {
			var
				recordDiv = $("<div>", {
					class: "b-tourist_search e-tourist_select_btn",
				})
				.data("id", record.getKey()),
				iconWrp = $("<span>", {
					class: "b-tourist_search e-icon_wrapper"
				}).appendTo(recordDiv),
				button = $("<div>", {
					class: "icon-small icon-append_item"
				}).appendTo(iconWrp),
				recordLink = $("<a>", {
					class: "b-tourist_search e-tourist_link",
					href: "#!",
					text: mkk_site.utils.getTouristInfoString(record)
				}).appendTo(recordDiv);
			
			return recordDiv;
		},
		
		activate: function(place)
		{
			this.$el(".e-block").detach().appendTo(place).show();
			if( this.recordSet && this.recordSet.getLength() )
				this.resultsPanel.show();
			else
				this.resultsPanel.hide()
		},
		
		deactivate: function(place)
		{
			this.$el(".e-block").detach().appendTo('body').hide();
		}
	});
})(webtank.ITEMControl);

//Редактирование руководителя и зам. руководителя похода
PohodChefEdit = (function(_super) {
	__extends(PohodChefEdit, _super);
	
	//Инициализация блока редактирования руководителя и зам. руководителя похода
	function PohodChefEdit(opts)
	{	
		_super.call(this, ".b-pohod_chef_edit");
		opts = opts || {}
		
		var
			self = this;
			
		this.elems = $(this.cssBlockName);
		this.searchBlock = opts.searchBlock;
		this.isAltChef = false;
		this.chefRecord = null;
		this.dialog = this.$el(".e-dlg");
		this.controlBar = this.$el('.e-control_bar');

		//Тык по кнопке удаления зам. руководителя похода
		this.$el(".e-delete_btn").$on("click", function() {
			self.$trigger('deleteChef', [self]);
			self.closeDialog();
		});
		
		this.dialog.$on( "dialogclose", this.onDialogClose.bind(this) );
	}
	
	return __mixinProto(PohodChefEdit, {
		//"Тык" по кнопке выбора руководителя или зама похода
		onSelectChef: function(ev, el, rec) {
			this.chefRecord = rec;
			this.$trigger( "selectChef", [this, rec] );
			this.closeDialog();
		},
		
		onDeleteChef: function(ev, el) {
			this.chefRecord = null;
			this.$trigger( "selectChef", [this] );
			this.closeDialog();
		},
		
		openDialog: function(record, isAltChef)
		{
			var dlgTitle = "";
			this.chefRecord = record;
			this.isAltChef = isAltChef;
			if( isAltChef ) {
				this.controlBar.show();
				dlgTitle = 'Выбор зам. руководителя';
			} else {
				this.controlBar.hide();
				dlgTitle = 'Выбор руководителя';
			}
			this.searchBlock.activate(this.$el(".e-search_block"));
			this.searchBlock.$on('itemSelect', this.onSelectChef.bind(this));
			this.dialog.dialog({modal: true, minWidth: 400, title: dlgTitle});
		},
		
		closeDialog: function() {
			this.dialog.dialog('close');
		},
		
		onDialogClose: function() {
			this.searchBlock.$off('itemSelect');
			this.searchBlock.deactivate();
		}
	});
})(webtank.ITEMControl);

PohodPartyEdit = (function(_super) {
	__extends(PohodPartyEdit, _super);
	
	//Инциализация блока редактирования списка участников
	function PohodPartyEdit(opts)
	{
		_super.call(this);
		opts = opts || {};
		
		var self = this;
		
		this.elems = $(".b-pohod_party_edit");
		this.selTouristsRS = null; //RecordSet с выбранными в поиске туристами
		this.page = 0;
		this.searchBlock = opts.searchBlock;
		this.dialog = this.$el(".e-dlg");
		this.panelsArea = self.$el(".e-panels_area");
		this.searchPanel = self.$el(".e-search_panel");
		this.selectedTouristsPanel = self.$el(".e-selected_tourists_panel");

		this.$el(".e-accept_btn").$on("click", function() {
			this.$trigger( 'saveData', [self, self.selTouristsRS] );
			self.closeDialog();
		});
		
		this.$el(".e-selected_tourists").$on( "click", ".e-tourist_deselect_btn", this.onDeselectTourist_BtnClick );
		this.dialog.$on( 'dialogclose', this.onDialogClose.bind(this) );
	}
	
	return __mixinProto(PohodPartyEdit, {
		openDialog: function(recordSet)
		{
			var 
				self = this;
				
			this.selTouristsRS = recordSet;
			this.renderSelectedTourists();
			this.searchBlock.activate(this.$el(".e-search_block"));
			this.searchBlock.$on('itemSelect', this.onSelectTourist.bind(this));
			this.dialog.dialog({
				modal: true, minWidth: 500,
				resize: function() {
					setTimeout( self.onDialogResize.bind(self), 100 );
				}
			});
			
			this.onDialogResize();
		},
		
		onDialogResize: function() {
			if( this.selTouristsRS && this.selTouristsRS.getLength() ) {
				if( this.dialog.innerWidth() < 700 ) {
					this.panelsArea.css("display", "block");
					this.searchPanel.css("display", "block");
					this.searchPanel.css("width", "100%");
					this.selectedTouristsPanel.css("display", "block");
					this.selectedTouristsPanel.css("width", "100%");
				} else {
					this.panelsArea.css("display", "table");
					this.searchPanel.css("display", "table-cell");
					this.searchPanel.css("width", "50%");
					this.selectedTouristsPanel.css("display", "table-cell");
					this.selectedTouristsPanel.css("width", "50%");
				}
			}
			else
			{
				this.panelsArea.css("display", "block");
				this.searchPanel.css("display", "block");
				this.searchPanel.css("width", "100%");
				this.selectedTouristsPanel.css("display", "none");
			}
		},
		
		closeDialog: function() {
			this.dialog.dialog('close');
		},
		
		onDialogClose: function() {
			this.searchBlock.deactivate();
			this.searchBlock.$off('itemSelect');
		},

		//Метод образует разметку с информацией о выбранном туристе
		renderSelectedTourist: function(rec)
		{	var
				recordDiv = $("<div>", {
					class: "b-pohod_party_edit e-tourist_deselect_btn"
				})
				.data( 'num', rec.get('num') ),
				iconWrp = $("<span>", {
					class: "b-pohod_party_edit e-icon_wrapper"
				}).appendTo(recordDiv),
				deselectBtn = $("<div>", {
					class: "icon-small icon-remove_item"
				}).appendTo(iconWrp),
				recordLink = $("<a>", {
					class: "b-pohod_party_edit e-tourist_link",
					href: "#!",
					text: mkk_site.utils.getTouristInfoString(rec)
				})
				.appendTo(recordDiv);
			
			return recordDiv;
		},
		
		//Обработчик добавления найденной записи о туристе
		onSelectTourist: function(ev, el, rec) {
			var 
				recordDiv,
				deselectBtn;
			
			if( !this.selTouristsRS )
			{	this.selTouristsRS = new webtank.datctrl.RecordSet({
					format: rec.copyFormat()
				});
			}
			
			if( this.selTouristsRS.hasKey( rec.getKey() ) )
			{	this.$el(".e-select_message").html(
					"Турист <b>" + mkk_site.utils.getTouristInfoString(rec)
					+ "</b> уже находится в списке выбранных туристов"
				);
			}
			else
			{	this.selTouristsRS.append(rec);
				this.renderSelectedTourist(rec)
				.appendTo( this.$el(".e-selected_tourists") );
			}
			
			this.onDialogResize(); //Перестройка диалога
		},
		
		//Обработчик отмены выбора записи
		onDeselectTourist_BtnClick: function(ev, el) {
			var 
				recId = el.data('num'),
				recordDiv = el,
				touristSelectDiv = this.$el(".e-selected_tourists");
			
			this.selTouristsRS.remove( recId );
			recordDiv.remove();
		},
		
		//Тык по кнопке открытия окна редактирования списка участников
		renderSelectedTourists: function() {
			var 
				self = this,
				selectedTouristsDiv = this.$el(".e-selected_tourists"),
				rec;
				
			//Очистка окна списка туристов перед заполнением
			selectedTouristsDiv.empty();
				
			this.selTouristsRS.rewind();
			while( rec = this.selTouristsRS.next() )
			{	this.renderSelectedTourist(rec)
				.data('num', rec.get('num'))
				.appendTo( selectedTouristsDiv );
			}
		}
	});
})(webtank.ITEMControl);

EditPohod = (function(_super) {
	__extends(EditPohod, _super);
	var dctl = webtank.datctrl;
	
	//Инициализация блока редактирования похода
	function EditPohod(opts)
	{	
		_super.call(this);
		opts = opts || {};
		
		var self = this;
		
		this.elems = $(".b-edit_pohod");
		this.chefEditBlock = opts.chefEditBlock;
		this.partyEditBlock = opts.partyEditBlock;
		this.participantsRS = null; //RecordSet с участниками похода
		this.chefRecord = null;
		this.altChefRecord = null;
		
		///Работа со списком ссылок на дополнительные ресурсы
		//Размер одной "порции" полей ввода ссылок на доп. материалы
		this.extraFileLinksInputPortion = 5;

		this.$el(".e-open_delete_dlg_btn").$on("click", function() {
			this.$el(".e-delete_dlg").dialog({modal: true});
		});

		this.$el(".e-delete_confirm_btn").$on("click", self.onDeleteConfirm_BtnClick);
		this.$el(".e-add_more_extra_file_links_btn").$on("click", self.onAddMoreExtraFileLinks_BtnClick);

		this.$el(".e-submit_btn").$on("click", function(ev){
			self.saveListOfExtraFileLinks( $(this), ev );
			self.$el(".e-edit_pohod_form").submit();
		});
		
		this.$el(".e-open_pohod_party_edit_btn").$on("click", function() {
			//Отдаем копию списка участников!
			var rs = self.participantsRS ? self.participantsRS.copy() : new dctl.RecordSet();
			self.partyEditBlock.openDialog(rs); 
		});
		
		this.partyEditBlock.$on( 'saveData', this.onSaveSelectedParticipants.bind(this) );
		
		//Загрузка списка участников похода с сервера
		this.loadParticipantsList();
		
		this.$el(".e-open_chef_edit_btn").$on( 'click', function() {
			this.chefEditBlock.openDialog(self.chefRecord, false);
		});
		
		this.$el(".e-open_alt_chef_edit_btn").$on( 'click', function() {
			this.chefEditBlock.openDialog(self.altChefRecord, true);
		});
		
		this.chefEditBlock.$on( "selectChef", this.onSelectChef.bind(this) );
		this.chefEditBlock.$on( "deleteChef", this.onDeleteChef.bind(this) );

		self.loadListOfExtraFileLinks();
	}
	
	return __mixinProto(EditPohod, {
		//Обработчик тыка по кнопке сохранения списка выбранных участников
		onSaveSelectedParticipants: function(ev, sender, selTouristsRS) {
			this.participantsRS = selTouristsRS;
			this.renderParticipantsList();
		},
		
		onSelectChef: function(ev, sender, rec) {
			var 
				keyInp = this.$el(sender.isAltChef ? '.e-alt_chef_key_inp' : '.e-chef_key_inp' ), 
				chefBtn = this.$el(sender.isAltChef ? '.e-open_alt_chef_edit_btn' : '.e-open_chef_edit_btn' );
			
			keyInp.val( rec.get("num") );
			chefBtn.text( mkk_site.utils.getTouristInfoString(rec) );
		},
		
		onDeleteChef: function(ev, sender, rec) {
			var 
				keyInp = this.$el(sender.isAltChef ? '.e-alt_chef_key_inp' : '.e-chef_key_inp' ), 
				chefBtn = this.$el(sender.isAltChef ? '.e-open_alt_chef_edit_btn' : '.e-open_chef_edit_btn' );
			
			keyInp.val("null");
			chefBtn.text("Редактировать");
		},
		
		//Выводит список участников похода из participantsRS в главное окно
		renderParticipantsList: function()
		{	var
				touristKeys = "",
				touristsList = this.$el(".e-tourists_list"),
				rec;

			touristsList.empty();
			
			this.participantsRS.rewind();
			while( rec = this.participantsRS.next() )
			{	touristKeys += ( touristKeys.length ? "," : "" ) + rec.getKey();
				$("<div>", {
					text: mkk_site.utils.getTouristInfoString(rec)
				})
				.appendTo(touristsList);
			}
			
			this.$el(".e-tourist_keys_inp").val(touristKeys);
		},
		
		//Загрузка списка участников похода
		loadParticipantsList: function()
		{	var 
				self = this,
				pohodKey = parseInt(getParams["key"], 10);
			
			if( isNaN(pohodKey) )
				return;
				
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.списокУчастниковПохода",
				params: { "pohodKey": pohodKey },
				success: function(json) {
					self.participantsRS = webtank.datctrl.fromJSON(json);
					self.renderParticipantsList();
				}
			});
		},

		//"Тык" по кнопке "Добавить ещё" (имеется в виду ссылок)
		onAddMoreExtraFileLinks_BtnClick: function()
		{	var
				i = 0,
				tableBody = this.$el(".e-link_list_tbody");

			for( ; i < this.extraFileLinksInputPortion; i++ )
				this.renderInputsForExtraFileLink([]).appendTo( tableBody );
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
				tableBody = $(".e-link_list_tbody"),
				inputPortion = this.extraFileLinksInputPortion,
				linkList = linkList ? linkList : [],
				inputCount = inputPortion,
				i = 0;

			if( linkList.length )
				inputCount = inputPortion - ( linkList.length - 1 ) % inputPortion;
			
			for( ; i < inputCount; i++ )
				this.renderInputsForExtraFileLink( linkList[i] ).appendTo(tableBody);
		},

		//Загрузка списка ссылок на доп. материалы с сервера
		loadListOfExtraFileLinks: function()
		{	var
				self = this,
				getParams = webtank.parseGetParams(),
				pohodKey = parseInt(getParams["key"], 10);
			
			if( isNaN(pohodKey) ) {
				this.renderListOfExtraFileLinks();
				return;
			}
			
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.списокСсылокНаДопМатериалы",
				params: { "pohodKey": pohodKey },
				success: function(data) { self.renderListOfExtraFileLinks(data) }
			});
		},

		//Сохранение списка ссылок на доп. материалы
		saveListOfExtraFileLinks: function()
		{	var
				self = this,
				tableRows = this.$el(".e-link_list_table").children("tbody").children("tr"),
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

			this.$el(".e-extra_file_links_inp").val( JSON.stringify(data) );
		},

		//Обработчик тыка по кнопке подтверждения удаления похода
		onDeleteConfirm_BtnClick: function() {
			var
				getParams = webtank.parseGetParams(),
				pohodKey = parseInt(getParams["key"], 10);
			
			if( this.$el(".e-delete_confirm_inp").val() === "удалить" )
			{
				webtank.json_rpc.invoke({
					uri: "/jsonrpc/",
					method: "mkk_site.edit_pohod.удалитьПоход",
					params: { "pohodKey": pohodKey }
				});
				document.location.replace("/dyn/show_pohod");
			}
			else
			{	this.$el(".e-delete_confirm_inp").val("Не подтверждено!!!")
			}
		}
	});
})(webtank.ITEMControl);


