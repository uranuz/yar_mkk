define('mkk/GeneralTemplate/GeneralTemplate', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/FilterMenu',
	'css!mkk/GeneralTemplate/GeneralTemplate'
], function(FirControl, FilterMenu) {
	__extends(GeneralTemplate, FirControl);

	function GeneralTemplate(opts) {
		opts = opts || {};
		FirControl.call(this, opts);
	}
	return __mixinProto(GeneralTemplate, {});
});