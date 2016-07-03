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

//Блок поиска туристов
mkk_site.TouristSearch = (function(_super) {
	__extends(TouristSearch, _super);
	
	function TouristSearch(opts)
	{
		opts = opts || {};
		_super.call(this, opts);
		
		var self = this;
		
		this.elems = $(this._cssBlockName);
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
mkk_site.PohodChefEdit = (function(_super) {
	__extends(PohodChefEdit, _super);
	
	//Инициализация блока редактирования руководителя и зам. руководителя похода
	function PohodChefEdit(opts)
	{	
		opts = opts || {}
		_super.call(this, opts);

		var
			self = this;
			
		this.elems = $(this._cssBlockName);
		this.searchBlock = opts.searchBlock;
		this.isAltChef = false;
		this.chefRec = null;
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
			this.chefRec = rec;
			this.$trigger( "selectChef", [this, rec] );
			this.closeDialog();
		},
		
		onDeleteChef: function(ev, el) {
			this.chefRec = null;
			this.$trigger( "selectChef", [this] );
			this.closeDialog();
		},
		
		openDialog: function(record, isAltChef)
		{
			var dlgTitle = "";
			this.chefRec = record;
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

mkk_site.PohodPartyEdit = (function(_super) {
	__extends(PohodPartyEdit, _super);
	
	//Инциализация блока редактирования списка участников
	function PohodPartyEdit(opts)
	{
		opts = opts || {};
		_super.call(this, opts);
		
		var self = this;
		
		this.elems = $(this._cssBlockName);
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

// Диалог подтверждения добавления руководителя похода и/или зама
// к списку участников
mkk_site.AddChefToPartyDlg = (function(_super) {
	__extends(AddChefToPartyDlg, _super);

	function AddChefToPartyDlg(opts)
	{
		opts = opts || {};
		_super.call(this, opts);

		this._dlg = this._elems().filter(".e-block");
		this._okBtn = this._elems().filter(".e-ok_btn");
		this._cancelBtn = this._elems().filter(".e-cancel_btn");
		this._touristsCountField = this._elems().filter(".e-tourists_count");

		this._okBtn.on( 'click', this.onOk_BtnClick.bind(this) );
		this._cancelBtn.on( 'click', this.onCancel_BtnClick.bind(this) );
	}

	return __mixinProto(AddChefToPartyDlg, {
		open: function(touristsCount) {
			this._touristsCountField.text( ( touristsCount || '[не задано]' ) + ' человек');
			this._dlg.dialog({
				modal: true,
				width: 400,
				close: this.onDlgClose.bind(this)
			});
		},

		onOk_BtnClick: function() {
			$(this).trigger( 'ok' );
		},

		onCancel_BtnClick: function() {
			this._dlg.dialog( 'close' );
		},

		onDlgClose: function() {
			$(this).trigger( 'cancel' );
		}
	});
})(webtank.ITEMControl);

mkk_site.EditPohod = (function(_super) {
	__extends(EditPohod, _super);
	var dctl = webtank.datctrl;
	
	//Инициализация блока редактирования похода
	function EditPohod(opts)
	{	
		opts = opts || {};
		_super.call(this, opts);
		
		var self = this;
		
		this.elems = $(this._cssBlockName);
		this.chefEditBlock = opts.chefEditBlock;
		this.partyEditBlock = opts.partyEditBlock;
		this.partyRS = null; //RecordSet с участниками похода
		this.chefRec = opts.chefRecord;
		this.altChefRec = opts.altChefRecord;
		this._addChefToPartyDlg = opts.addChefToPartyDlg;

		this._beginDatePicker = new webtank.ui.PlainDatePicker({
			controlName: 'pohod_begin_date_picker'
		});

		this._finishDatePicker = new webtank.ui.PlainDatePicker({
			controlName: 'pohod_finish_date_picker'
		});
		
		///Работа со списком ссылок на дополнительные ресурсы
		//Размер одной "порции" полей ввода ссылок на доп. материалы
		this.extraFileLinksInputPortion = 5;

		this.$el(".e-open_delete_dlg_btn").$on("click", function() {
			this.$el(".e-delete_dlg").dialog({modal: true});
		});

		this.$el(".e-delete_confirm_btn").$on("click", self.onDeleteConfirm_BtnClick);
		this.$el(".e-add_more_extra_file_links_btn").$on("click", self.onAddFileLinkInputs_BtnClick);

		this.$el(".e-submit_btn").$on( "click", this.onSavePohod_BtnClick.bind(this) );
		
		this.$el(".e-open_pohod_party_edit_btn").$on("click", function() {
			//Отдаем копию списка участников!
			var rs = self.partyRS ? self.partyRS.copy() : new dctl.RecordSet();
			self.partyEditBlock.openDialog(rs); 
		});
		
		this.partyEditBlock.$on( 'saveData', this.onSaveSelectedParty.bind(this) );
		
		//Загрузка списка участников похода с сервера
		this.loadPartyFromServer();
		
		this.$el(".e-open_chef_edit_btn").$on( 'click', function() {
			this.chefEditBlock.openDialog(self.chefRec, false);
		});
		
		this.$el(".e-open_alt_chef_edit_btn").$on( 'click', function() {
			this.chefEditBlock.openDialog(self.altChefRec, true);
		});
		
		this.chefEditBlock.$on( "selectChef", this.onSelectChef.bind(this) );
		this.chefEditBlock.$on( "deleteChef", this.onDeleteChef.bind(this) );

		self.loadFileLinksFromServer();
	}
	
	return __mixinProto(EditPohod, {
		//Обработчик тыка по кнопке сохранения списка выбранных участников
		onSaveSelectedParty: function(ev, sender, selTouristsRS) {
			this.saveParty(selTouristsRS);
		},
		
		onSelectChef: function(ev, sender, rec) {
			var 
				keyInp = this.$el(sender.isAltChef ? '.e-alt_chef_key_inp' : '.e-chef_key_inp' ),
				chefBtn = this.$el(sender.isAltChef ? '.e-open_alt_chef_edit_btn' : '.e-open_chef_edit_btn' );
			
			if( sender.isAltChef ) {
				this.altChefRec = rec;
			} else {
				this.chefRec = rec;
			}

			keyInp.val( rec.get("num") );
			chefBtn.text( mkk_site.utils.getTouristInfoString(rec) );
		},
		
		onDeleteChef: function(ev, sender) {
			var 
				keyInp = this.$el(sender.isAltChef ? '.e-alt_chef_key_inp' : '.e-chef_key_inp' ),
				chefBtn = this.$el(sender.isAltChef ? '.e-open_alt_chef_edit_btn' : '.e-open_chef_edit_btn' );
			
			if( sender.isAltChef ) {
				this.altChefRec = null;
			} else {
				this.chefRec = null;
			}

			keyInp.val("null");
			chefBtn.text("Редактировать");
		},
		
		//Сохраняет список участников группы и выводит его в главное окно
		saveParty: function( rs ) {
			var
				touristsList = this.$el(".e-tourists_list"),
				rec;

			this.partyRS = rs;

			touristsList.empty();
			
			this.partyRS.rewind();
			while( rec = this.partyRS.next() ) {
				$("<div>", {
					text: mkk_site.utils.getTouristInfoString(rec)
				})
				.appendTo(touristsList);
			}
		},

		//Загрузка списка участников похода
		loadPartyFromServer: function() {
			var
				self = this,
				pohodKey = parseInt(getParams["key"], 10);
			
			if( isNaN(pohodKey) )
				return;
				
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.списокУчастниковПохода",
				params: { "pohodKey": pohodKey },
				success: function(json) {
					self.saveParty( webtank.datctrl.fromJSON(json) );
				}
			});
		},

		//"Тык" по кнопке "Добавить ещё" (имеется в виду ссылок)
		onAddFileLinkInputs_BtnClick: function()
		{	var
				i = 0,
				tableBody = this.$el(".e-link_list_tbody");

			for( ; i < this.extraFileLinksInputPortion; i++ )
				this.renderFileLinkInput([]).appendTo( tableBody );
		},

		//Создает элементы для ввода ссылки с описанием на доп. материалы
		renderFileLinkInput: function(data)
		{	var
				newTr = $("<tr>"),
				leftTd = $("<td>").appendTo(newTr),
				rightTd = $("<td>").appendTo(newTr),
				linkInput = $( "<input>", { type: "text", class: "form-control" } ).appendTo(leftTd),
				commentInput = $( "<input>", { type: "text", class: "form-control" } ).appendTo(rightTd);

			if( data )
			{	linkInput.val( data[0] || "" );
				commentInput.val( data[1] || "" );
			}

			return newTr;
		},

		//Отображает список ссылок на доп. материалы
		renderFileLinkInputs: function(linkList)
		{	var
				tableBody = $(".e-link_list_tbody"),
				inputPortion = this.extraFileLinksInputPortion,
				linkList = linkList ? linkList : [],
				inputCount = inputPortion,
				i = 0;

			if( linkList.length )
				inputCount = inputPortion - ( linkList.length - 1 ) % inputPortion;
			
			for( ; i < inputCount; i++ )
				this.renderFileLinkInput( linkList[i] ).appendTo(tableBody);
		},

		//Загрузка списка ссылок на доп. материалы с сервера
		loadFileLinksFromServer: function()
		{	var
				self = this,
				getParams = webtank.parseGetParams(),
				pohodKey = parseInt(getParams["key"], 10);
			
			if( isNaN(pohodKey) ) {
				this.renderFileLinkInputs();
				return;
			}
			
			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.списокСсылокНаДопМатериалы",
				params: { "pohodKey": pohodKey },
				success: function(data) { self.renderFileLinkInputs(data) }
			});
		},

		//Сохранение списка ссылок на доп. материалы
		saveFileLinksToForm: function()
		{	var
				self = this,
				tableRows = this.$el(".e-link_list_tbody").children("tr"),
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

		showErrorDialog: function( errorMsg ) {
			$('<div title="Ошибка ввода">' + errorMsg + '</div>').dialog({ modal: true, width: 350 });
		},

		// Функция проверки данных формы перед отправкой
		validateFormData: function() {
			var
				self = this,
				beginDay = self._beginDatePicker.rawDay(),
				beginMonth = self._beginDatePicker.rawMonth(),
				beginYear = self._beginDatePicker.rawYear(),
				finishDay = self._finishDatePicker.rawDay(),
				finishMonth = self._finishDatePicker.rawMonth(),
				finishYear = self._finishDatePicker.rawYear(),
				beginDateEmpty = !beginDay.length && !beginMonth.length && !beginYear.length,
				finishDateEmpty = !finishDay.length && !finishMonth.length && !finishYear.length,
				countInput = self.$el(".e-tourist_count_input")
				inputCount = parseInt( countInput.val() ),
				listItems = self.$el(".e-tourists_list").children(),
				listCount = listItems.length;

			if( !beginDateEmpty && ( !beginDay.length || !beginMonth.length || !beginYear.length ) ) {
				self.showErrorDialog( 'Нужно заполнить все поля даты начала, либо оставить их все пустыми' );
				return false;
			}

			if( !finishDateEmpty && ( !finishDay.length || !finishMonth.length || !finishYear.length ) ) {
				self.showErrorDialog( 'Нужно заполнить все поля даты завершения, либо оставить их все пустыми' );
				return false;
			}

			if( beginDay.length > 0 ) {
				if( !mkk_site.checkInt( beginDay, 1, 31 ) ) {
					self.showErrorDialog( 'День начала похода должен быть целым числом в диапазоне [1, 31]' );
					return false;
				}
			}

			if( finishDay.length > 0 ) {
				if( !mkk_site.checkInt( finishDay, 1, 31 ) ) {
					self.showErrorDialog( 'День завершения похода должен быть целым числом в диапазоне [1, 31]' );
					return false;
				}
			}

			if( beginYear.length > 0 ) {
				if( !mkk_site.checkInt( beginYear, 1000, 9999 ) ) {
					self.showErrorDialog( 'Год начала похода должен быть четырехзначным целым числом' );
					return false;
				}
			}

			if( finishYear.length > 0 ) {
				if( !mkk_site.checkInt( finishYear, 1000, 9999 ) ) {
					self.showErrorDialog( 'Год завершения похода должен быть четырехзначным целым числом' );
					return false;
				}
			}

			if( !beginDateEmpty && !finishDateEmpty &&
				(  new Date( +beginYear, +beginMonth, +beginDay ) > new Date( +finishYear, +finishMonth, +finishDay )  ) ) {
				self.showErrorDialog( 'Дата начала похода не может быть позже даты его завершения' );
				return false;
			}

			if( countInput.val().length && !mkk_site.checkInt( inputCount, 0 ) ) {
				self.showErrorDialog( 'Требуется ввести неотрицательное целое число в поле количества участников' );
				return false;
			}

			if( mkk_site.checkInt( inputCount, 9000 ) ) {
				self.showErrorDialog( 'Вы должно быть шутите?! В вашем походе более 9000 участников?!?!' );
				return false;
			}

			if( listCount > inputCount ) {
				self.showErrorDialog( 'Количество участников в списке '  + listCount + ' больше числа в поле ввода '
					+ inputCount + '. Пожалуйста, исправьте введенное значение' );
				return false;
			}

			return true;
		},

		// Заполняет поля формы из объекта класса
		fillFormFields: function() {
			var
				chefKeyField = this.$el('.e-chef_key_inp'),
				altChefKeyField = this.$el('.e-alt_chef_key_inp'),
				partyKeysField = this.$el('.e-tourist_keys_inp'),
				touristKeys = '';

			if( this.chefRec ) {
				chefKeyField.val( this.chefRec.get('num') );
			} else {
				chefKeyField.val( 'null' )
			}

			if( this.altChefRec ) {
				altChefKeyField.val( this.altChefRec.get('num') );
			} else {
				altChefKeyField.val( 'null' );
			}

			if( this.partyRS ) {
				this.partyRS.rewind();
				while( rec = this.partyRS.next() ) {
					touristKeys += ( touristKeys.length ? "," : "" ) + rec.getKey();
				}

				partyKeysField.val(touristKeys);
			} else {
				partyKeysField.val( 'null' );
			}

			this.saveFileLinksToForm();
		},

		// Возвражает true, если нужно добавить руководителя в список участников
		shouldAddChefToParty: function() {
			return !!this.chefRec && !this.partyRS.hasKey( this.chefRec.get('num') );
		},

		// Возвражает true, если нужно добавить зама в список участников
		shouldAddAltChefToParty: function() {
			return !!this.altChefRec && !this.partyRS.hasKey( this.altChefRec.get('num') );
		},

		getPartySizeFromInput: function() {
			return parseInt( this.$el('.e-tourist_count_input').val() ) || null;
		},

		// Функция корректировки значения количества участников для поля ввода
		getNewPartySizeForInput: function() {
			var
				rsCount = this.partyRS ? this.partyRS.getLength() : 0,
				inpCount = this.getPartySizeFromInput();
				newRSCount = rsCount,
				newInpCount = inpCount;

			if( inpCount != null ) {
				if( this.shouldAddChefToParty() ) {
					++newRSCount;
				}

				if( this.shouldAddAltChefToParty() ) {
					++newRSCount;
				}

				if( newRSCount > inpCount )
					newInpCount = newRSCount;
			}

			return newInpCount;
		},

		// Выполняет проверку данных. Записывает данные о походе из JS-класса в форму.
		// Отправляет данные на сервер после проверки
		onSavePohod: function() {
			// Добавляем к списку участников руководителя и зама
			if( this.shouldAddChefToParty() ) {
				this.partyRS.append( this.chefRec );
			}

			if( this.shouldAddAltChefToParty() ) {
				this.partyRS.append( this.altChefRec );
			}

			// Устанавливаем новое количество участников, если оно было не пустым
			this.$el( '.e-tourist_count_input' ).val( this.getNewPartySizeForInput() );

			if( this.validateFormData() ) {
				this.fillFormFields(); // Пишем данные в поля формы
				this.$el(".e-edit_pohod_form").submit();
			}
		},

		// Обработчик тыка по кнопке сохранения похода
		onSavePohod_BtnClick: function(ev) {
			var
				self = this,
				newTouristsCount = this.getNewPartySizeForInput(),
				shouldAddChef = this.shouldAddChefToParty(),
				shouldAddAltChef = this.shouldAddAltChefToParty(),
				cancelHandler = function() {
					ev.preventDefault();
				};

			// Сами отправим форму, когда нужно сами
			ev.preventDefault();

			if( self.chefRec == null ) {
				self.showErrorDialog( 'Необходимо выбрать руководителя похода!' );
				ev.preventDefault();
				return;
			}

			if( self.partyRS == null ) {
				self.partyRS = new dctl.RecordSet({
					format: self.chefRec.copyFormat()
				});
			}

			if( shouldAddChef || shouldAddAltChef ) {
				// Если есть записи руководителя и зама, но их нет в списке
				// участников, то открываем диалог подтверждения их добавления
				$(this._addChefToPartyDlg).one( 'ok', this.onSavePohod.bind(this) );
				$(this._addChefToPartyDlg).one( 'cancel', cancelHandler );

				this._addChefToPartyDlg.open( newTouristsCount );

			} else {
				// Если руководитель и зам есть, то сразу продолжаем
				this.onSavePohod();
			}
		},

		//Обработчик тыка по кнопке подтверждения удаления похода
		onDeleteConfirm_BtnClick: function() {
			var
				getParams = webtank.parseGetParams(),
				pohodKey = parseInt(getParams["key"], 10);
			
			if( this.$el(".e-delete_confirm_inp").val() === "удалить" ) {
				webtank.json_rpc.invoke({
					uri: "/jsonrpc/",
					method: "mkk_site.edit_pohod.удалитьПоход",
					params: { "pohodKey": pohodKey }
				});
				document.location.replace("/dyn/show_pohod");
			}
			else {
				this.$el(".e-delete_confirm_inp").val("Не подтверждено!!!")
			}
		}
	});
})(webtank.ITEMControl);

//Инициализация страницы
$(window.document).ready( function() {
	var
		chefRecord = null,
		altChefRecord = null;

	if( mkk_site.pohod_chef_record ) {
		chefRecord = webtank.datctrl.fromJSON( mkk_site.pohod_chef_record );
	}

	if( mkk_site.pohod_alt_chef_record ) {
		altChefRecord = webtank.datctrl.fromJSON( mkk_site.pohod_alt_chef_record );
	}

	//Инициализаци блоков на странице
	mkk_site.tourist_search = new mkk_site.TouristSearch({
		cssBlockName: ".b-tourist_search"
	});
	mkk_site.pohod_chef_edit = new mkk_site.PohodChefEdit({
		cssBlockName: ".b-pohod_chef_edit",
		searchBlock: mkk_site.tourist_search
	});
	mkk_site.pohod_party_edit = new mkk_site.PohodPartyEdit({
		cssBlockName: ".b-pohod_party_edit",
		searchBlock: mkk_site.tourist_search
	});
	mkk_site.add_chef_to_party_dlg = new mkk_site.AddChefToPartyDlg({
		controlName: "add_chef_to_party_dlg"
	});

	mkk_site.edit_pohod = new mkk_site.EditPohod({
		cssBlockName: ".b-edit_pohod",
		chefEditBlock: mkk_site.pohod_chef_edit,
		partyEditBlock: mkk_site.pohod_party_edit,
		chefRecord: chefRecord,
		altChefRecord: altChefRecord,
		addChefToPartyDlg: mkk_site.add_chef_to_party_dlg
	});
} );