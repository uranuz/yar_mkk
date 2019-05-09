define('mkk/Tourist/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'fir/controls/Pagination/Pagination',
	'css!mkk/Tourist/List/List'
], function (FirControl, NavigationMixin) {
var
	ENTER_KEY_CODE = 13,
	searchOnEnterFields = [
		'familyNameField',
		'givenNameField',
		'patronymicField'
	];
return FirClass(
	function TouristList(opts) {
		this.superproto.constructor.call(this, opts);
		this._navigatedArea = 'tableContentBody';
	}, FirControl, [NavigationMixin], {
		_onSubscribe: function() {
			NavigationMixin._onSubscribe.apply(this, arguments);
			this._elems('searchBtn').on('click', this._onSearch_start.bind(this));

			var
				self = this,
				bindedHandler = this._onFilterInput_KeyUp.bind(this);
			searchOnEnterFields.forEach(function(fieldName) {
				self._elems(fieldName).on('keyup', bindedHandler);
			});
		},

		_onUnsubscribe: function() {
			NavigationMixin._onUnsubscribe.apply(this, arguments);
			this._elems('searchBtn').off();
			var self = this;
			searchOnEnterFields.forEach(function(fieldName) {
				self._elems(fieldName).off('keyup');
			});
		},

		_onFilterInput_KeyUp: function(ev) {
			if( ev.keyCode === ENTER_KEY_CODE ) {
				this._onSearch_start(); // Запускаем поиск при нажатии на кнопку Enter на поле ввода
			}
		},

		_onSearch_start: function() {
			this._onSetCurrentPage();
		},

		/** Имя RPC-метода. Если указано, то запрос идет через RPC-протокол */
		_getRPCMethod: function(areaName) {
			return 'tourist.list';
		},

		getFilter: function() {
			var
				textFields = ['familyName', 'givenName', 'patronymic'],
				params = {},
				field, val;
			for( var i = 0; i < textFields.length; ++i ) {
				field = textFields[i];
				val = this._elems(field + 'Field').val();
				if( val ) {
					params[field] = val.trim();
				}
			}
			return params;
		},
		/**
		 * Параметры, передаваемые на основной сервис, предпочтительно через адресную строку (для REST-запросов)
		 * Но для RPC-вызовов эти параметры добавляются к параметрам метода
		 */
		_getQueryParams: function(areaName) {
			return {
				filter: this.getFilter(),
				nav: this.getNavParams()
			};
		}
	}
);
});