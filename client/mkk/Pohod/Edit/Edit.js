define('mkk/Pohod/Edit/Edit', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'mkk/helpers',
	'mkk/Helpers/DeleteConfirm/DeleteConfirm',
	'mkk/Pohod/Edit/Party/Party',
	'mkk/Pohod/Edit/Chief/Edit/Edit',
	'mkk/Pohod/Edit/Chief/AddToParty/AddToParty',
	'mkk/Tourist/NavList/NavList',
	'mkk/Pohod/Edit/ExtraFileLinks/ExtraFileLinks',
	'css!mkk/Pohod/Edit/Edit'
], function (
	FirControl,
	FirHelpers,
	json_rpc,
	MKKHelpers
) {
return FirClass(
	function PohodEdit(opts) {
		this.superproto.constructor.call(this, opts);
		var self = this;
		this._chiefRec = this._partyList.getRecord(this._pohod.get('chiefNum'));
		this._altChiefRec = this._partyList.getRecord(this._pohod.get('altChiefNum'));

		this._chiefEditDlg = this.getChildByName('chiefEditDlg');
		this._partyEditDlg = this.getChildByName('partyEditDlg');
		this._beginDatePicker = this.getChildByName('beginDateField');
		this._finishDatePicker = this.getChildByName('finishDateField');
		this._deleteConfirmDlg = this.getChildByName('deleteConfirmDlg');
		this._partyListCtrl = this.getChildByName('partyList');
		this._extraFileLinks = this.getChildByName('extraFileLinksEdit');
		this._chiefAddToParty = this.getChildByName('chiefAddToParty');

		this._partyListCtrl.setFilterGetter(this.getPartyListFilter.bind(this));

		this._elems("deleteDialogBtn").on("click", function() {
			self._deleteConfirmDlg.open({});
		});

		this._deleteConfirmDlg.subscribe('dialogControlLoad', function(ev, control) {
			control.subscribe('onDeleteConfirm', self.onDeleteConfirm.bind(this));
		});

		this._elems("submitBtn").on("click", this.onSubmitBtn_click.bind(this));

		this._partyEditDlg.subscribe('dialogControlLoad', function(ev, control) {
			control.subscribe('saveData', self.onSaveSelectedParty.bind(self));
		});
		this._elems("partyEditBtn").on("click", function() {
			self._partyEditDlg.open({
				queryParams: {
					filter: {
						nums: (self._partyList? self._partyList.getKeys(): [])
					},
					nav: {}
				}
			}); 
		});

		this._chiefEditDlg.subscribe('dialogControlLoad', function(ev, control) {
			control.subscribe("selectChief", this.onSelectChief.bind(this));
			control.subscribe("deleteChief", this.onDeleteChief.bind(this));
		}.bind(this));

		this._elems("chiefEditBtn").on('click', this.onChiefEditBtn_click.bind(this, false));
		this._elems("altChiefEditBtn").on('click', this.onChiefEditBtn_click.bind(this, true));
	}, FirControl, {
		//Обработчик тыка по кнопке сохранения списка выбранных участников
		onSaveSelectedParty: function(ev, selTouristsRS) {
			this.saveParty(selTouristsRS);
		},

		onChiefEditBtn_click: function(isAltChief) {
			this._chiefEditDlg.open({
				viewParams: {
					isAltChief: isAltChief
				},
				dialogOpts: {
					title: (isAltChief? 'Выбор зам. руководителя': 'Выбор руководителя')
				}
			});
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

		/** Возвращает параметры фильтрации для списка участников */
		getPartyListFilter: function() {
			return {
				nums: this._partyList.getKeys()
			};
		},
		
		//Сохраняет список участников группы и выводит его в главное окно
		saveParty: function(rs) {
			this._partyList = rs;
			this._partyListCtrl._reloadControl();
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
				listCount = this._partyList.getLength();

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
				self.showErrorDialog('Количество участников в списке ' + listCount + ' больше заявленного числа '
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

			if( this._partyList ) {
				partyKeysField.val(this._partyList.getKeys());
			} else {
				partyKeysField.val('null');
			}

			this._extraFileLinks.saveFileLinksToForm();
		},

		// Вернёт true, если нужно добавить руководителя в список участников
		shouldAddChiefToParty: function() {
			return !!this._chiefRec && !this._partyList.hasKey( this._chiefRec.get('num') );
		},

		// Вернёт true, если нужно добавить зама в список участников
		shouldAddAltChiefToParty: function() {
			return !!this._altChiefRec && !this._partyList.hasKey( this._altChiefRec.get('num') );
		},

		getPartySizeFromInput: function() {
			return parseInt( this._elems('partySize').val() ) || null;
		},

		// Функция корректировки значения количества участников для поля ввода
		getNewPartySizeForInput: function() {
			var
				rsCount = this._partyList ? this._partyList.getLength() : 0,
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
				this._partyList.append( this._chiefRec );
			}

			if( this.shouldAddAltChiefToParty() ) {
				this._partyList.append( this._altChiefRec );
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

			if( self._partyList == null ) {
				self._partyList = new dctl.RecordSet({
					format: self._chiefRec.getFormat().copy()
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