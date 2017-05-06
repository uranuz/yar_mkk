define('mkk/ModerList/ModerList', [
	'fir/controls/ITEMControl'
], function (ITEMControl) {
	__extends(ModerList, ITEMControl);

	function ModerList(opts) {
		opts = opts || {};
		ITEMControl.call(this, opts);

	}
	return __mixinProto(ModerList, {});
});