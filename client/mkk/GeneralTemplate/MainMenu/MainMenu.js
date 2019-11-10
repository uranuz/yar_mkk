define('mkk/GeneralTemplate/MainMenu/MainMenu', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/MainMenu/UserMenuBtn/UserMenuBtn',
	'mkk/GeneralTemplate/MainMenu/MainMenu.scss'
], function(FirControl) {
return FirClass(
	function MainMenu(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});