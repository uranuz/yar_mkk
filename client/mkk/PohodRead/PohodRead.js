define('mkk/PohodRead/PohodRead', [
	'fir/controls/FirControl',
	'css!mkk/PohodRead/PohodRead'
], function (FirControl) {
	__extends(PohodRead, FirControl);

	function PohodRead(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(PohodRead, {});
});