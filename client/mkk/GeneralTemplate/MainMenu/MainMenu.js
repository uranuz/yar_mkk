define('mkk/GeneralTemplate/MainMenu/MainMenu', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/MainMenu/UserMenuBtn/UserMenuBtn',
	'css!mkk/GeneralTemplate/MainMenu/MainMenu'
], function(FirControl) {
	__extends(MainMenu, FirControl);

	function MainMenu(opts) {
		FirControl.call(this, opts);
	}

	return __mixinProto(MainMenu, {});
});