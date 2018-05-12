define('mkk/Right/ObjectRightList/ObjectRightList', [
	'fir/controls/FirControl',
	'css!mkk/Right/ObjectRightList/ObjectRightList'
], function (FirControl) {
	__extends(ObjectRightList, FirControl);

	function ObjectRightList(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(ModerList, {});
});