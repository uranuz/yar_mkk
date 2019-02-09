define('mkk/User/Reg/EmailConfirm/EmailConfirm', [
	'fir/controls/FirControl',
	'css!mkk/User/Reg/EmailConfirm/EmailConfirm'
], function(FirControl) {
	__extends(EmailConfirm, FirControl);
	function EmailConfirm(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(EmailConfirm, {});
});