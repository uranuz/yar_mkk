define('mkk/Right/Object/List/List', [
	'fir/controls/FirControl',
	'css!mkk/Right/Object/List/List'
], function (FirControl) {
return FirClass(
	function RightObjectList(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});