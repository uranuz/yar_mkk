define('mkk/User/Reg/EmailConfirm/EmailConfirm', [
	'fir/controls/FirControl',
	'css!mkk/User/Reg/EmailConfirm/EmailConfirm'
], function(FirControl) {
return FirClass(
	function EmailConfirm(opts) {
		FirControl.call(this, opts);
	}, FirControl
);
});