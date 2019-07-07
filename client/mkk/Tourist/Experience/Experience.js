define('mkk/Tourist/Experience/Experience', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/Tourist/Experience/Experience'
], function (FirControl, FirHelpers) {
return FirClass(
	function TouristExperience(opts) {
		this.superctor(TouristExperience, opts);
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: 'tableContentBody',
			navOpt: 'nav',
			replaceURIState: true
		});
	}, FirControl, {
		_getQueryParams: function(areaName) {
			return {
				num: this._tourist.get('num'),
				nav: this._paging.getNavParams()
			};
		}
	}
);
});