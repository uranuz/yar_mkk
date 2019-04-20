define('mkk/Tourist/Experience/Experience', [
	'fir/controls/FirControl',
	'mkk/Helpers/NavigationMixin',
	'fir/controls/Pagination/Pagination',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/Tourist/Experience/Experience'
], function (FirControl, NavigationMixin) {
return FirClass(
	function TouristExperience(opts) {
		this.superproto.constructor.call(this, opts);
		this._tourist = opts.tourist;
		this._navigatedArea = 'tableContentBody';
	}, FirControl, [NavigationMixin], {
		/** Имя RPC-метода. Если указано, то запрос идет через RPC-протокол */
		_getRPCMethod: function(areaName) {
			return 'tourist.experience';
		},

		/**
		 * Параметры, передаваемые на основной сервис, предпочтительно через адресную строку (для REST-запросов)
		 * Но для RPC-вызовов эти параметры добавляются к параметрам метода
		 */
		_getQueryParams: function(areaName) {
			return {
				num: this._tourist.get('num'),
				nav: this.getNavParams()
			};
		}
	}
);
});