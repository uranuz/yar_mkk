define('mkk/PohodEdit/PohodEdit', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'fir/datctrl/Record',
	'fir/datctrl/RecordSet',
	'fir/datctrl/helpers',
	'mkk/helpers',
	'css!mkk/PohodEdit/PohodEdit'
], function (
	FirControl,
	CommonHelpers,
	json_rpc,
	Record,
	RecordSet,
	DatctrlHelpers,
	MKKHelpers
) {
	__extends(PohodEdit, FirControl);

	//Инициализация блока редактирования похода
	function PohodEdit(opts)
	{	
		FirControl.call(this, opts);
		var self = this;

		this._partyRS = DatctrlHelpers.fromJSON(opts.partyList); //RecordSet с участниками похода
		this._chiefRec = opts.chiefRecord;
		this._altChiefRec = opts.altChiefRecord;
		this._addChiefToPartyDlg = opts.addChiefToPartyDlg;

		this._chiefEditBlock = this.getChildInstanceByName('pohodChiefEdit');
		this._partyEditBlock = this.getChildInstanceByName('partyEdit');
		this._beginDatePicker = this.getChildInstanceByName('beginDateField');
		this._finishDatePicker = this.getChildInstanceByName('finishDateField');
		this._pohodDeleteArea = this.getChildInstanceByName('pohodDeleteArea');
		this._partyList = this.getChildInstanceByName('partyList');

		///Работа со списком ссылок на дополнительные ресурсы
		//Размер одной "порции" полей ввода ссылок на доп. материалы
		this._extraFileLinksInputPortion = 5;

		this._elems("deleteDialogBtn").on("click", function() {
			self._pohodDeleteArea.showDialog();
		});

		this._pohodDeleteArea.subscribe('onDeleteConfirm', self.onDeleteConfirm.bind(this));
		this._elems("moreExtraFileLinksBtn").on("click", self.onMoreExtraFileLinksBtn_click);

		this._elems("submitBtn").on("click", this.onSubmitBtn_click.bind(this));
		this._elems("partyEditBtn").on("click", function() {
			//Отдаем копию списка участников!
			var rs = self._partyRS ? self._partyRS.copy() : new RecordSet();
			self._partyEditBlock.openDialog(rs); 
		});
		
		this._partyEditBlock.subscribe('saveData', this.onSaveSelectedParty.bind(this));

		this._elems("chiefEditBtn").on('click', function() {
			self._chiefEditBlock.openDialog(self._chiefRec, false);
		});
		
		this._elems("altChiefEditBtn").on('click', function() {
			self._chiefEditBlock.openDialog(self._altChiefRec, true);
		});
		
		this._chiefEditBlock.subscribe("selectChief", this.onSelectChief.bind(this));
		this._chiefEditBlock.subscribe("deleteChief", this.onDeleteChief.bind(this));

		//self.loadFileLinksFromServer();
	}
	
	return __mixinProto(PohodEdit, {
		//Обработчик тыка по кнопке сохранения списка выбранных участников
		onSaveSelectedParty: function(ev, selTouristsRS) {
			this.saveParty(selTouristsRS);
		},
		
		onSelectChief: function(ev, rec) {
			var
				sender = ev.target,
				keyInp = this._elems(sender.isAltChief? 'altChiefNumField': 'chiefNumField'),
				chiefBtn = this._elems(sender.isAltChief? 'altChiefEditBtn': 'chiefEditBtn');

			if( sender.isAltChief ) {
				this._altChiefRec = rec;
			} else {
				this._chiefRec = rec;
			}

			keyInp.val( rec.get("num") );
			chiefBtn.text( MKKHelpers.getTouristInfoString(rec) );
		},
		
		onDeleteChief: function(ev) {
			var
				sender = ev.target,
				keyInp = this._elems(sender.isAltChief? 'altChiefNumField': 'chiefNumField'),
				chiefBtn = this._elems(sender.isAltChief? 'altChiefEditBtn': 'chiefEditBtn');

			if( sender.isAltChief ) {
				this._altChiefRec = null;
			} else {
				this._chiefRec = null;
			}

			keyInp.val("null");
			chiefBtn.text("Редактировать");
		},
		
		//Сохраняет список участников группы и выводит его в главное окно
		saveParty: function(rs) {
			var rec, selectedKeys = [];

			this._partyRS = rs;
			this._partyRS.rewind();
			while( rec = this._partyRS.next() ) {
				selectedKeys.push( rec.getKey() );
			}

			// Передаём список идентификаторов туристов в фильтр компонента отображения списка туристов...
			this._partyList.setFilter({
				selectedKeys: selectedKeys
			});
			// ...и обновляем компонент
			this._partyList._reloadControl();
		},

		//"Тык" по кнопке "Добавить ещё" (имеется в виду ссылок)
		onMoreExtraFileLinksBtn_click: function()
		{	var
				i = 0,
				tableBody = this._elems("extraFileLinksTableBody");

			for( ; i < this._extraFileLinksInputPortion; i++ )
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
				tableBody = this._elems("extraFileLinksTableBody"),
				inputPortion = this._extraFileLinksInputPortion,
				linkList = linkList? linkList: [],
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
				tableRows = this._elems("extraFileLinksTableBody").children("tr"),
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

			this._elems("extraFileLinksDataField").val( JSON.stringify(data) );
		},

		showErrorDialog: function(errorMsg) {
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
				countInput = self._elems("partySizeField")
				inputCount = parseInt(countInput.val()),
				listItems = self._elems("partyList").children(),
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
				chiefKeyField = this._elems('chiefNumField'),
				altChiefKeyField = this._elems('altChiefNumField'),
				partyKeysField = this._elems('partyNumsField'),
				touristKeys = '';

			if( this._chiefRec ) {
				chiefKeyField.val(this._chiefRec.get('num'));
			} else {
				chiefKeyField.val('null')
			}

			if( this._altChiefRec ) {
				altChiefKeyField.val(this._altChiefRec.get('num'));
			} else {
				altChiefKeyField.val('null');
			}

			if( this._partyRS ) {
				this._partyRS.rewind();
				while( rec = this._partyRS.next() ) {
					touristKeys += ( touristKeys.length ? "," : "" ) + rec.getKey();
				}

				partyKeysField.val(touristKeys);
			} else {
				partyKeysField.val('null');
			}

			this.saveFileLinksToForm();
		},

		// Возвражает true, если нужно добавить руководителя в список участников
		shouldAddChiefToParty: function() {
			return !!this._chiefRec && !this._partyRS.hasKey( this._chiefRec.get('num') );
		},

		// Возвражает true, если нужно добавить зама в список участников
		shouldAddAltChiefToParty: function() {
			return !!this._altChiefRec && !this._partyRS.hasKey( this._altChiefRec.get('num') );
		},

		getPartySizeFromInput: function() {
			return parseInt( this._elems('partySize').val() ) || null;
		},

		// Функция корректировки значения количества участников для поля ввода
		getNewPartySizeForInput: function() {
			var
				rsCount = this._partyRS ? this._partyRS.getLength() : 0,
				inpCount = this.getPartySizeFromInput();
				newRSCount = rsCount,
				newInpCount = inpCount;

			if( inpCount != null ) {
				if( this.shouldAddChiefToParty() ) {
					++newRSCount;
				}

				if( this.shouldAddAltChiefToParty() ) {
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
			if( this.shouldAddChiefToParty() ) {
				this._partyRS.append( this._chiefRec );
			}

			if( this.shouldAddAltChiefToParty() ) {
				this._partyRS.append( this._altChiefRec );
			}

			// Устанавливаем новое количество участников, если оно было не пустым
			this._elems('partySize').val( this.getNewPartySizeForInput() );

			if( this.validateFormData() ) {
				this.fillFormFields(); // Пишем данные в поля формы
				this._elems("mainForm").submit();
			}
		},

		// Обработчик тыка по кнопке сохранения похода
		onSubmitBtn_click: function(ev) {
			var
				self = this,
				newTouristsCount = this.getNewPartySizeForInput(),
				shouldAddChief = this.shouldAddChiefToParty(),
				shouldAddAltChief = this.shouldAddAltChiefToParty(),
				cancelHandler = function() {
					ev.preventDefault();
				};

			// Сами отправим форму, когда нужно
			ev.preventDefault();

			if( self._chiefRec == null ) {
				self.showErrorDialog('Необходимо выбрать руководителя похода!');
				ev.preventDefault();
				return;
			}

			if( self._partyRS == null ) {
				self._partyRS = new dctl.RecordSet({
					format: self._chiefRec.copyFormat()
				});
			}

			if( shouldAddChief || shouldAddAltChief ) {
				// Если есть записи руководителя и зама, но их нет в списке
				// участников, то открываем диалог подтверждения их добавления
				$(this._addChiefToPartyDlg).one('ok', this.onSavePohod.bind(this));
				$(this._addChiefToPartyDlg).one('cancel', cancelHandler);

				this._addChiefToPartyDlg.open(newTouristsCount);

			} else {
				// Если руководитель и зам есть, то сразу продолжаем
				this.onSavePohod();
			}
		},

		//Обработчик тыка по кнопке подтверждения удаления похода
		onDeleteConfirm: function() {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "pohod.delete",
				params: { "num": parseInt(CommonHelpers.parseGetParams()["key"], 10) },
				success: function() {
					document.location.replace("/dyn/pohod/list");
				},
				error: function(res) {
					$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
				}
			});
		}
	});
});