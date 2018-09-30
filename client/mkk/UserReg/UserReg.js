define('mkk/UserReg/UserReg', [
	'fir/controls/FirControl',
	'mkk/TouristEdit/TouristEdit',
	'css!mkk/UserReg/UserReg'
], function (FirControl) {
	__extends(UserReg, FirControl);
	function UserReg(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(UserReg, {

	});
});