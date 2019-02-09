define('mkk/Pohod/Edit/Edit', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'fir/datctrl/Record',
	'fir/datctrl/RecordSet',
	'fir/datctrl/helpers',
	'mkk/helpers',
	'mkk/Pohod/Edit/DeleteArea/DeleteArea',
	'mkk/Pohod/Edit/Party/Party',
	'mkk/Pohod/Edit/Chief/Edit/Edit',
	'mkk/Pohod/Edit/Chief/AddToParty/AddToParty',
	'mkk/Tourist/NavigatedList/NavigatedList',
	'mkk/Pohod/Edit/ExtraFileLinks/ExtraFileLinks',
	'css!mkk/Pohod/Edit/Edit'
], function (
	FirControl,
	FirHelpers,
	json_rpc,
	Record,
	RecordSet,
	DatctrlHelpers,
	MKKHelpers
) {
return FirClass(
	function PohodEdit(opts) {
		this.superproto.constructor.call(this, opts);
		var self = this;

		this._partyRS = DatctrlHelpers.fromJSON(opts.partyList); // RecordSet с участниками похода
		this._origPohodRec = DatctrlHelpers.fromJSON(opts.pohod); // Запись похода при загрузке компонента
		this._chiefRec = this._partyRS.getRecord(this._origPohodRec.get('chiefNum'));
		this._altChiefRec = this._partyRS.getRecord(this._origPohodRec.get('altChiefNum'));

		this._chiefEditBlock = this.getChildInstanceByName('pohodChiefEdit');
		this._partyEditBlock = this.getChildInstanceByName('partyEdit');
		this._beginDatePicker = this.getChildInstanceByName('beginDateField');
		this._finishDatePicker = this.getChildInstanceByName('finishDateField');
		this._pohodDeleteArea = this.getChildInstanceByName('pohodDeleteArea');
		this._partyList = this.getChildInstanceByName('partyList');
		this._extraFileLinks = this.getChildInstanceByName('extraFileLinksEdit');
		this._chiefAddToParty = this.getChildInstanceByName('chiefAddToParty');

		this._elems("deleteDialogBtn").on("click", function() {
			self._pohodDeleteArea.showDialog();
		});

		this._pohodDeleteArea.subscribe('onDeleteConfirm', self.onDeleteConfirm.bind(this));

		this._elems("submitBtn").on("click", this.onSubmitBtn_click.bind(this));
		this._elems("partyEditBtn").on("click", function() {
			//Отдаем копию списка участников!
			var rs = self._partyRS? self._partyRS.copy() : new RecordSet();
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

		this._partyList.setFilter({
			selectedKeys: this.getPartyNums()
		});
	}, FirControl, {
		//Обработчик тыка по кнопке сохранения списка выбранных участников
		onSaveSelectedParty: function(ev, selTouristsRS) {
			this.saveParty(selTouristsRS);
		},
		
		onSelectChief: function(ev, rec, isAltChief) {
			var
				keyInp = this._elems(isAltChief? 'altChiefNumField': 'chiefNumField'),
				chiefBtn = this._elems(isAltChief? 'altChiefEditBtn': 'chiefEditBtn');

			if( isAltChief ) {
				this._altChiefRec = rec;
			} else {
				this._chiefRec = rec;
			}

			keyInp.val( rec.get("num") );
			chiefBtn.text( MKKHelpers.getTouristInfoString(rec) );
		},
		
		onDeleteChief: function(ev, rec, isAltChief) {
			var
				keyInp = this._elems(isAltChief? 'altChiefNumField': 'chiefNumField'),
				chiefBtn = this._elems(isAltChief? 'altChiefEditBtn': 'chiefEditBtn');

			if( isAltChief ) {
				this._altChiefRec = null;
			} else {
				this._chiefRec = null;
			}

			keyInp.val("null");
			chiefBtn.text("Редактировать");
		},

		/** Получить идентификаторы участников группы */
		getPartyNums: function() {
			var selectedKeys = [], rec;
			for( this._partyRS.rewind(); rec = this._partyRS.next(); ) {
				selectedKeys.push( rec.getKey() );
			}
			return selectedKeys;
		},

		/** Обновить отображение списка группы */
		updatePartyList: function() {
			// Передаём список идентификаторов туристов в фильтр компонента отображения списка туристов...
			this._partyList.setFilter({
				selectedKeys: this.getPartyNums()
			});
			// ...и обновляем компонент
			this._partyList._reloadControl();
		},
		
		//Сохраняет список участников группы и выводит его в главное окно
		saveParty: function(rs) {
			this._partyRS = rs;
			this.updatePartyList();
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
				listCount = this._partyRS.getLength();

			if( !beginDateEmpty && (!beginDay.length || !beginMonth.length || !beginYear.length) ) {
				self.showErrorDialog('Нужно заполнить все поля даты начала, либо оставить их все пустыми');
				return false;
			}

			if( !finishDateEmpty && (!finishDay.length || !finishMonth.length || !finishYear.length) ) {
				self.showErrorDialog('Нужно заполнить все поля даты завершения, либо оставить их все пустыми');
				return false;
			}

			if( beginDay.length > 0 ) {
				if( !MKKHelpers.checkInt(beginDay, 1, 31) ) {
					self.showErrorDialog('День начала похода должен быть целым числом в диапазоне [1, 31]');
					return false;
				}
			}

			if( finishDay.length > 0 ) {
				if( !MKKHelpers.checkInt(finishDay, 1, 31) ) {
					self.showErrorDialog('День завершения похода должен быть целым числом в диапазоне [1, 31]');
					return false;
				}
			}

			if( beginYear.length > 0 ) {
				if( !MKKHelpers.checkInt(beginYear, 1000, 9999) ) {
					self.showErrorDialog('Год начала похода должен быть четырехзначным целым числом');
					return false;
				}
			}

			if( finishYear.length > 0 ) {
				if( !MKKHelpers.checkInt(finishYear, 1000, 9999) ) {
					self.showErrorDialog('Год завершения похода должен быть четырехзначным целым числом');
					return false;
				}
			}

			if( !beginDateEmpty && !finishDateEmpty &&
				(new Date(+beginYear, +beginMonth, +beginDay) > new Date(+finishYear, +finishMonth, +finishDay)) ) {
				self.showErrorDialog('Дата начала похода не может быть позже даты его завершения');
				return false;
			}

			if( countInput.val().length && !MKKHelpers.checkInt(inputCount, 0) ) {
				self.showErrorDialog('Требуется ввести неотрицательное целое число в поле количества участников');
				return false;
			}

			if( MKKHelpers.checkInt(inputCount, 9000) ) {
				self.showErrorDialog('Вы должно быть шутите?! В вашем походе более 9000 участников?!?!');
				return false;
			}

			if( listCount > inputCount ) {
				self.showErrorDialog('Количество участников в списке '  + listCount + ' больше заявленного числа '
					+ inputCount + '. Пожалуйста, исправьте введенное значение');
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

			this._extraFileLinks.saveFileLinksToForm();
		},

		// Вернёт true, если нужно добавить руководителя в список участников
		shouldAddChiefToParty: function() {
			return !!this._chiefRec && !this._partyRS.hasKey( this._chiefRec.get('num') );
		},

		// Вернёт true, если нужно добавить зама в список участников
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
				this._chiefAddToParty.once('ok', this.onSavePohod.bind(this));
				this._chiefAddToParty.once('ok', cancelHandler);
				this._chiefAddToParty.open(newTouristsCount);
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
				params: { "num": parseInt(FirHelpers.parseGetParams()["num"], 10) },
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