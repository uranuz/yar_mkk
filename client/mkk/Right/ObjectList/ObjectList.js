define('mkk/Right/ObjectList/ObjectList', [
	'fir/controls/FirControl',
	'css!mkk/Right/ObjectList/ObjectList'
], function (FirControl) {
return FirClass(
	function RightObjectList(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});