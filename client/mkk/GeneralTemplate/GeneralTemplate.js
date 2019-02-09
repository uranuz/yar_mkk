define('mkk/GeneralTemplate/GeneralTemplate', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/MainMenu/MainMenu',
	'mkk/GeneralTemplate/FilterMenu/FilterMenu',
	'css!mkk/GeneralTemplate/GeneralTemplate',
	'css!mkk/page_styles'
], function(FirControl) {
return FirClass(
	function GeneralTemplate(opts) {
		FirControl.call(this, opts);
	}, FirControl
)
});