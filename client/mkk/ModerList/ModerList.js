define('mkk/ModerList/ModerList', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(ModerList, FirControl);

	function ModerList(opts) {
		opts = opts || {};
		FirControl.call(this, opts);
	}
	return __mixinProto(ModerList, {});
});