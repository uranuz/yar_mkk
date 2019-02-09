define('mkk/GeneralTemplate/MainMenu/MainMenu', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/MainMenu/UserMenuBtn/UserMenuBtn',
	'css!mkk/GeneralTemplate/MainMenu/MainMenu'
], function(FirControl) {
return FirClass(
	function MainMenu(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});