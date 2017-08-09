define('mkk/GeneralTemplate/GeneralTemplate', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/FilterMenu',
	'css!mkk/GeneralTemplate/GeneralTemplate',
	'css!mkk/page_styles'
], function(FirControl, FilterMenu) {
	__extends(GeneralTemplate, FirControl);

	function GeneralTemplate(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(GeneralTemplate, {});
});