define('mkk/Tourist/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'fir/controls/Pagination/Pagination',
	'css!mkk/Tourist/List/List'
], function (FirControl, NavigationMixin) {
return FirClass(
	function TouristList(opts) {
		this.superproto.constructor.call(this, opts);
		this._navigatedArea = 'tableContentBody';
	}, FirControl, [NavigationMixin], {
		_onSubscribe: function() {
			NavigationMixin._onSubscribe.apply(this, arguments);
			this._elems('searchBtn').on('click', this._onSearchBtnClick.bind(this));
		},

		_onUnsubscribe: function() {
			NavigationMixin._onUnsubscribe.apply(this, arguments);
			this._elems('searchBtn').off();
		},

		_onSearchBtnClick: function() {
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