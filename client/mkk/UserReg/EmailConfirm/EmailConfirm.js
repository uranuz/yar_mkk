define('mkk/UserReg/EmailConfirm/EmailConfirm', [
	'fir/controls/FirControl',
	'css!mkk/UserReg/EmailConfirm/EmailConfirm'
], function(FirControl) {
	__extends(EmailConfirm, FirControl);
	function EmailConfirm(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(EmailConfirm, {});
});