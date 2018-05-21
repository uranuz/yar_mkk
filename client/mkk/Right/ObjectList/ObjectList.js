define('mkk/Right/ObjectList/ObjectList', [
	'fir/controls/FirControl',
	'css!mkk/Right/ObjectList/ObjectList'
], function (FirControl) {
	__extends(RightObjectList, FirControl);

	function RightObjectList(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(RightObjectList, {});
});