define('mkk/GeneralTemplate/MainMenu/MainMenu', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/MainMenu/UserMenuBtn/UserMenuBtn',
	'css!mkk/GeneralTemplate/MainMenu/MainMenu'
], function(FirControl) {
return FirClass(
	function MainMenu(opts) {
		FirControl.call(this, opts);
	}, FirControl
);
});