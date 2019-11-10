define('mkk/Tourist/List/List', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'mkk/Tourist/List/List.scss'
], function (FirControl, FirHelpers) {
var
	searchOnEnterFields = [
		'familyNameField',
		'givenNameField',
		'patronymicField'
	];
return FirClass(
	function TouristList(opts) {
		this.superctor(TouristList, opts);
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		this._reloadList = this._reloadControl.bind(this, 'tableContentBody');
		FirHelpers.doOnEnter(this, searchOnEnterFields, this._reloadList);
		this._subscr(function() {
			this._elems('searchBtn').on('click', this._reloadList);
		});
		this._unsubscr(function() {
			this._elems('searchBtn').off();
		});

		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: 'tableContentBody',
			navOpt: 'nav',
			replaceURIState: true
		});
	}, FirControl, {
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
				nav: this._paging.getNavParams()
			};
		}
	}
);
});