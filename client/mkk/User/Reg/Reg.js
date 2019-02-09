define('mkk/User/Reg/Reg', [
	'fir/controls/FirControl',
	'mkk/Tourist/Edit/Edit',
	'css!mkk/User/Reg/Reg'
], function (FirControl) {
	__extends(UserReg, FirControl);
	function UserReg(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(UserReg, {

	});
});