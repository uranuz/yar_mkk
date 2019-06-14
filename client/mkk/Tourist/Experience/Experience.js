define('mkk/Tourist/Experience/Experience', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/Tourist/Experience/Experience'
], function (FirControl, NavigationMixin) {
return FirClass(
	function TouristExperience(opts) {
		this.superctor(TouristExperience, opts);
		this._navigatedArea = 'tableContentBody';
	}, FirControl, [NavigationMixin], {
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