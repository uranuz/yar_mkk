define('mkk/Tourist/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'fir/common/helpers',
	'css!mkk/Tourist/List/List'
], function (FirControl, NavigationMixin, helpers) {
var
	searchOnEnterFields = [
		'familyNameField',
		'givenNameField',
		'patronymicField'
	];
return FirClass(
	function TouristList(opts) {
		this.superctor(TouristList, opts);
		this._navigatedArea = 'tableContentBody';
		this._subscr(function() {
			this._elems('searchBtn').on('click', this._onSearch_start.bind(this));
			searchOnEnterFields.forEach(function(fieldName) {
				helpers.doOnEnter(this._elems(fieldName), this._onSearch_start.bind(this));
			});
		});
		this._unsubscr(function() {
			this._elems('searchBtn').off();
			searchOnEnterFields.forEach(function(fieldName) {
				this._elems(fieldName).off('keyup');
			}.bind(this));
		});
	}, FirControl, [NavigationMixin], {

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