define('mkk/PohodEdit/PohodEdit', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'fir/datctrl/Record',
	'fir/datctrl/RecordSet',
	'fir/datctrl/helpers'
], function (
	FirControl,
	CommonHelpers,
	json_rpc,
	Record,
	RecordSet,
	DatctrlHelpers
) {
	__extends(PohodEdit, FirControl);

	//Инициализация блока редактирования похода
	function PohodEdit(opts)
	{	
		FirControl.call(this, opts);
		var self = this;

		this.partyRS = null; //RecordSet с участниками похода
		this.chefRec = opts.chefRecord;
		this.altChefRec = opts.altChefRecord;
		this._addChefToPartyDlg = opts.addChefToPartyDlg;

		this._chefEditBlock = this.getChildInstanceByName('pohodChiefEdit');
		this._partyEditBlock = this.getChildInstanceByName('partyEdit');
		this._beginDatePicker = this.getChildInstanceByName('beginDateField');
		this._finishDatePicker = this.getChildInstanceByName('finishDateField');

		///Работа со списком ссылок на дополнительные ресурсы
		//Размер одной "порции" полей ввода ссылок на доп. материалы
		this.extraFileLinksInputPortion = 5;

		this._elems("deleteDialogBtn").on("click", function() {
			self.getChildInstanceByName('pohodDeleteArea').showDialog();
		});

		this._elems("deleteConfirmBtn").on("click", self.onDeleteConfirmBtn_click);
		this._elems("moreExtraFileLinksBtn").on("click", self.onMoreExtraFileLinksBtn_click);

		this._elems("submitBtn").on("click", this.onSubmitBtn_click.bind(this));
		this._elems("partyEditBtn").on("click", function() {
			//Отдаем копию списка участников!
			var rs = self.partyRS ? self.partyRS.copy() : new RecordSet();
			self.partyEditBlock.openDialog(rs); 
		});
		
		//this.partyEditBlock.$on('saveData', this.onSaveSelectedParty.bind(this));
		
		//Загрузка списка участников похода с сервера
		//this.loadPartyFromServer();
		
		this._elems("chiefEditBtn").on('click', function() {
			self._chefEditBlock.openDialog(self.chefRec, false);
		});
		
		this._elems("chiefEditBtn").on('click', function() {
			self._chefEditBlock.openDialog(self.altChefRec, true);
		});
		
		this._chefEditBlock.subscribe("selectChef", this.onSelectChef.bind(this));
		this._chefEditBlock.subscribe("deleteChef", this.onDeleteChef.bind(this));

		//self.loadFileLinksFromServer();
	}
	
	return __mixinProto(PohodEdit, {
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
				pohodKey = parseInt(CommonHelpers.parseGetParams()["key"], 10);
			
			if( isNaN(pohodKey) )
				return;
				
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.списокУчастниковПохода",
				params: { "pohodKey": pohodKey },
				success: function(json) {
					self.saveParty( DatctrlHelpers.fromJSON(json) );
				}
			});
		},

		//"Тык" по кнопке "Добавить ещё" (имеется в виду ссылок)
		onMoreExtraFileLinksBtn_click: function()
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
				getParams = CommonHelpers.parseGetParams(),
				pohodKey = parseInt(getParams["key"], 10);
			
			if( isNaN(pohodKey) ) {
				this.renderFileLinkInputs();
				return;
			}
			
			json_rpc.invoke({
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
		onSubmitBtn_click: function(ev) {
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
		onDeleteConfirm: function() {
			var pohodKey = parseInt(CommonHelpers.parseGetParams()["key"], 10);

			if( this.$el(".e-delete_confirm_inp").val() === "удалить" ) {
				json_rpc.invoke({
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
});