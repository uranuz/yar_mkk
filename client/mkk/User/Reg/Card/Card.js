define('mkk/User/Reg/Card/Card', [
	'fir/controls/FirControl',
	'mkk/Tourist/Edit/Edit',
	'mkk/User/Reg/Card/Card.scss'
], function (FirControl) {
return FirClass(
	function UserRegCard(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems('regBtn').on('click', this._onRegBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('regBtn').off('click');
		});
		this.getValidation().addValidators([{
			elem: 'loginField',
			fn: this._checkLogin
		}, {
			elem: 'passwordField',
			fn: this._checkPassword
		}, {
			elem: 'passwordConfirmField',
			fn: this._checkPasswordConfirm
		}]);
	}, FirControl, {
		getValidation: function() {
			return this.getChildByName(this.instanceName() + 'Validation');
		},
		_checkLogin: function(vld) {
			var val = vld.elem.val().trim();
			if( !val.length ) {
				return 'Необходимо задать логин пользователя';
			}
			if( val.length < this._settings.minLoginLength ) {
				return 'Нужно задать логин, состоящий хотя бы из ' + this._settings.minLoginLength + ' символов';
			}
		},
		_checkPassword: function(vld) {
			var val = vld.elem.val().trim();
			if( !val.length ) {
				return 'Необходимо задать пароль пользователя';
			}
			if( val.length < this._settings.minPasswordLength ) {
				return 'Нужно задать пароль, состоящий хотя бы из ' + this._settings.minPasswordLength + ' символов';
			}
		},
		_checkPasswordConfirm: function(vld) {
			var val = vld.elem.val().trim();
			if( !val.length ) {
				return 'Необходимо повторить ввод пароля';
			}
			if( vld.elem.val() !== this._elems('passwordField').val() ) {
				return 'Пароль и подтверждение пароля не совпадают';
			}
		},
		_onRegBtn_click: function(ev) {
			if( !this.getValidation().validate() ) {
				ev.preventDefault(); // Валидация не прошла - ничего не делаем
				return;
			}
			this._elems('regForm').submit();
		}
	}
);
});