define('mkk/User/Reg/Reg', [
	'fir/controls/FirControl',
	'mkk/Tourist/Edit/Edit',
	'css!mkk/User/Reg/Reg'
], function (FirControl) {
return FirClass(
	function UserReg(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});