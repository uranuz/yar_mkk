define('mkk/Tourist/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/helpers',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'fir/controls/PlainDatePicker/PlainDatePicker',
	'fir/controls/PlainListBox/PlainListBox',
	'mkk/Tourist/PlainList/PlainList',
	'mkk/Pohod/Edit/DeleteArea/DeleteArea',
	'css!mkk/Tourist/Edit/Edit'
], function(FirControl, MKKHelpers, FirHelpers, json_rpc) {
return FirClass(
	function TouristEdit(opts) {
		FirControl.call(this, opts);

		this._isEditDialog = opts.isEditDialog;
		this._checkRights = opts.checkRights;

		this._elems('submitBtn').click(this.sendButtonClick.bind(this));

		this._birthDatePicker = this.getChildInstanceByName('birthDateField');
		this._similarsList = this.getChildInstanceByName('similarsList');
		this._touristForm = this._elems('touristForm');
		this._similarsDlg = this._elems("similarsDlg");
		this._forceSubmitBtn = this._elems("forceSubmitBtn");
		this._touristDeleteArea = this.getChildInstanceByName('touristDeleteArea');
		this._partyList = this.getChildInstanceByName('partyList');
		this._extraFileLinks = this.getChildInstanceByName('extraFileLinksEdit');
		this._chiefAddToParty = this.getChildInstanceByName('chiefAddToParty');

		if( this._isEditDialog ) {
			this._elems("deleteDialogBtn").on("click", this._touristDeleteArea.showDialog.bind(this));
			this._touristDeleteArea.subscribe('onDeleteConfirm', this.onDeleteConfirm.bind(this));
		}

		this._updateControlState(opts);
	}, FirControl, {
		_subscribeInternal: function() {
			this._similarsList.subscribe('onTouristListLoaded', this.processSimilarTourists.bind(this));
			this._forceSubmitBtn.on('click', this._forcedSubmitForm.bind(this));
		},
		_unsubscibeInternal: function() {
			this._similarsList.unsubscribe('onTouristListLoaded');
			this._forceSubmitBtn.off('click');
		},
		_forcedSubmitForm: function() {
			this._touristForm.submit();
		},
		processSimilarTourists: function(ev, rs, nav) {
			if (rs && rs.getLength()) {
				this._similarsDlg.dialog({title: "Добавление туриста", modal: true, width: 450});
			} else {
				this._forcedSubmitForm();
			}
		},

		showErrorDialog: function( errorMsg ) {
			$('<div title="Ошибка ввода">' + errorMsg + '</div>').dialog({ modal: true, width: 350 });
		},

		/** Проверка данных формы */
		validateFormData: function() {
			var
				self = this,
				familyName = this._elems('familyName').val(),
				givenName = this._elems('givenName').val(),
				birthYear = this._birthDatePicker.rawYear(),
				birthMonth = this._birthDatePicker.rawMonth(),
				birthDay = this._birthDatePicker.rawDay();

			if( !givenName.trim() || !familyName.trim() ) {
				self.showErrorDialog('Необходимо ввести фамилию и имя туриста!');
				return false;
			}

			if( birthDay.length && !MKKHelpers.checkInt(birthDay, 1, 31) ) {
				self.showErrorDialog('День рождения должен быть целым числом в диапазоне [1, 31]');
				return false;
			}

			if( birthYear.length && !MKKHelpers.checkInt(birthYear, 1000, 9999) ) {
				self.showErrorDialog('Год рождения похода должен быть четырехзначным целым числом');
				return false;
			}

			return true;
		},

		sendButtonClick: function(ev) {
			var
				self = this,
				el = $(ev.target),
				touristKey = NaN,
				touristForm = this._elems('touristForm'),
				birthYear = parseInt(this._birthDatePicker.rawYear(), 10);

			if( !self.validateFormData() ) {
				ev.preventDefault();
				return;
			}

			if( isNaN(birthYear) ) {
				birthYear = null;
			}

			try {
				touristKey = parseInt(FirHelpers.parseGetParams().num, 10);
			} catch(e) {
				touristKey = NaN;
			}

			// Если ключ не передан (новый турист), и находимся в разделе
			if( isNaN(touristKey) && this._isEditDialog ) {
				this._similarsList.setFilter({
					familyName: this._elems('familyName').val(),
					givenName: this._elems('givenName').val(),
					patronymic: this._elems('patronymic').val(),
					birthYear: birthYear
				});
				this._similarsList._reloadControl();
			} else {
				//Редактирование существующего
				this._forcedSubmitForm();
			}
		},

		//Обработчик тыка по кнопке подтверждения удаления туриста
		onDeleteConfirm: function() {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "tourist.delete",
				params: { "num": parseInt(FirHelpers.parseGetParams()["num"], 10) },
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