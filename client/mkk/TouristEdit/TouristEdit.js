define('mkk/TouristEdit/TouristEdit', [
	'fir/controls/FirControl',
	'fir/datctrl/helpers',
	'css!mkk/TouristEdit/TouristEdit'
], function(FirControl, DatctrlHelpers) {
	__extends(TouristEdit, FirControl);

	function TouristEdit(opts) {
		FirControl.call(this, opts);
		var self = this;
		this._elems('submitBtn').click(this.sendButtonClick.bind(this));

		this._birthDatePicker = this.getChildInstanceByName('birthDateField');
		this._similarsList = this.getChildInstanceByName('similarsList');
		this._touristForm = this._elems('touristForm');
		this._similarsDlg = this._elems("similarsDlg");
		this._forceSubmitBtn = this._elems("forceSubmitBtn");

		this._updateControlState(opts);
	}

	return __mixinProto(TouristEdit, {
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
				this._similarsDlg.dialog({title: "Добавление туриста", modal: true});
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

			if( birthDay.length && !mkk_site.checkInt( birthDay, 1, 31 ) ) {
				self.showErrorDialog('День рождения должен быть целым числом в диапазоне [1, 31]');
				return false;
			}

			if( birthYear.length && !mkk_site.checkInt( birthYear, 1000, 9999 ) ) {
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
				touristKey = parseInt(webtank.parseGetParams().key, 10);
			} catch(e) {
				touristKey = NaN;
			}

			if( isNaN(touristKey) ) {
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
		}
	});
});