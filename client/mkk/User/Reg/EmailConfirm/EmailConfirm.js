define('mkk/User/Reg/EmailConfirm/EmailConfirm', [
	'fir/controls/FirControl',
	'mkk/User/Reg/EmailConfirm/EmailConfirm.scss'
], function(FirControl) {
return FirClass(
	function EmailConfirm(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});