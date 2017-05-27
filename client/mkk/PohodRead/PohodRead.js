define('mkk/PohodRead/PohodRead', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(PohodRead, FirControl);

	function PohodRead(opts) {
		opts = opts || {};
		FirControl.call(this, opts);
	}
	return __mixinProto(PohodRead, {});
});