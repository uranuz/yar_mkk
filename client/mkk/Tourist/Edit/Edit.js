define('mkk/Tourist/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/helpers',
	'fir/network/json_rpc',
	'fir/datctrl/ivy/Deserializer',
	'fir/controls/PlainDatePicker/PlainDatePicker',
	'fir/controls/PlainListBox/PlainListBox',
	'mkk/Tourist/PlainList/PlainList',
	'mkk/Helpers/DeleteConfirm/DeleteConfirm',
	'mkk/Tourist/Edit/Edit.scss'
], function(
	FirControl,
	MKKHelpers,
	json_rpc,
	IvyDeserializer
) {
return FirClass(
	function TouristEdit(opts) {
		this.superproto.constructor.call(this, opts);

		this._birthDatePicker = this.getChildByName('birthDateField');
		this._touristForm = this._elems('touristForm');
		this._touristSimilarDlg = this.getChildByName('touristSimilarDlg');
		this._deleteConfirmDlg = this.getChildByName('deleteConfirmDlg');
		this._partyList = this.getChildByName('partyList');
		this._extraFileLinks = this.getChildByName('extraFileLinksEdit');
		this._chiefAddToParty = this.getChildByName('chiefAddToParty');
		if( this._isEditDialog ) {
			this._deleteConfirmDlg.subscribe('dialogControlLoad', function(ev, control) {
				control.subscribe('onDeleteConfirm', this.onDeleteConfirm.bind(this));
			}.bind(this));
		}

		this._subscr(function() {
			this._elems('submitBtn').on('click', this._onSendButton_click.bind(this));
			if( this._isEditDialog ) {
				this._elems("deleteDialogBtn").on("click", function() {
					this._deleteConfirmDlg.open();
				}.bind(this));
			}
			this.getValidation().subscribe('onValidate', function(ev, isValid) {
				//this._elems('submitBtn').toggleClass('btn-primary', isValid);
				this._elems('submitBtn').toggleClass('btn-outline-danger', !isValid);
			}.bind(this));
		});

		this._unsubscr(function() {
			this._elems('submitBtn').off('click');
			if( this._isEditDialog ) {
				this._elems("deleteDialogBtn").off('click');
			}
		});

		// Базовые валидаторы, общие для редактирования и регистрации пользователя
		this.getValidation().addValidators([{
				control: this.getChildByName('birthDateField'),
				elem: 'yearField',
				fn: this._checkBirthYear
		}]);

		if( !this._isEditDialog ) {
			// При регистрации пользователя нужно выполнять валидацию основных полей
			this.getValidation().addValidators([{
				elem: 'familyNameField', fn: this._checkNonEmpty
			}, {
				elem: 'givenNameField', fn: this._checkNonEmpty
			}, {
				elem: 'emailField', fn: this._checkEmail
			}, {
				control: this.getChildByName('birthDateField'),
				elem: 'block',
				fn: this._checkBirthDate
			}]);
		}

	}, FirControl, {
		_forcedSubmitForm: function() {
			this._touristForm.submit();
		},
		processSimilarTourists: function(ev, rs, nav) {
			if (rs && rs.length) {
				this._similarsDlg.dialog({title: "Добавление туриста", modal: true, width: 450});
			} else {
				this._forcedSubmitForm();
			}
		},
		_checkNonEmpty: function(vld) {
			return !!vld.elem.val().trim().length || 'Поле обязательно для заполнения';
		},

		_checkBirthDate: function(vld) {
			var ctrl = vld.control;
			if( ctrl.getDate() == null ) {
				return 'Требуется указать вашу дату рождения';
			}
		},

		_checkBirthYear: function(vld) {
			var birthYear = vld.control.getYear();
			return (
				(birthYear == null || MKKHelpers.checkInt(birthYear, 1000, 9999))
				|| 'Год рождения должен быть целым четырехзначным числом'
			);
		},

		_checkEmail: function(vld) {
			var val = vld.elem.val().trim();
			if( !val.length || !val.match(/^.+@.+\..+$/) ) {
				return 'Необходимо указать действительный адрес электронной почты';
			}
		},
		
		getValidation: function() {
			return this.getChildByName(this.instanceName() + 'Validation');
		},

		// Возвращает идентификатор текущего туриста
		getNum: function() {
			var num = parseInt(this._elems('numField').val(), 10);
			return isNaN(num)? null: num;
		},

		_onSendButton_click: function(ev) {
			var birthYear = parseInt(this._birthDatePicker.rawYear(), 10);
			if( isNaN(birthYear) ) {
				birthYear = null;
			}

			if( !this.getValidation().validate() ) {
				ev.preventDefault();
				return;
			}

			// Если ключ не передан (новый турист), и находимся в разделе
			if( this._isEditDialog && this.getNum() == null ) {
				// Проверяем - нет ли в базе похожих туристов.
				// Возможно, что турист уже действительно есть, и добавлять его не надо тогда...
				json_rpc.invoke({
					uri: "/jsonrpc/",
					method: "tourist.plainList",
					params: {
						filter: {
							familyName: this._elems('familyNameField').val() || undefined,
							givenName: this._elems('givenNameField').val() || undefined,
							patronymic: this._elems('patronymicField').val() || undefined,
							birthYear: birthYear || undefined
						},
						nav: {}
					},
					success: this._onSimilarTourists_load.bind(this),
					error: function(res) {
						$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
					}
				});
			} else {
				//Редактирование существующего
				this._forcedSubmitForm();
			}
		},

		/** Загрузка списка похожих туристов. Список может быть и пустой. То значит, что похожих нет... */
		_onSimilarTourists_load: function(rawData) {
			var data = IvyDeserializer.deserialize(rawData);
			if( data.touristList.length ) {
				this._touristSimilarDlg.open({
					RPCMethod: null, // Не зови метод
					viewParams: data
				});
			} else {
				this._forcedSubmitForm();
			}
		},


		// Обработчик тыка по кнопке подтверждения удаления туриста
		onDeleteConfirm: function() {
			var touristNum = this.getNum();
			if( touristNum == null ) {
				return;
			}
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "tourist.delete",
				params: {num: touristNum},
				success: function() {
					document.location.replace("/dyn/tourist/list");
				},
				error: function(res) {
					$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
				}
			});
		}
});
});