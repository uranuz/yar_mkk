define('mkk/GeneralTemplate/GeneralTemplate', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/MainMenu/MainMenu',
	'mkk/GeneralTemplate/FilterMenu/FilterMenu',
	'mkk/GeneralTemplate/GeneralTemplate.scss',
	'mkk/page_styles.scss'
], function(FirControl) {
return FirClass(
	function GeneralTemplate(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
)
});