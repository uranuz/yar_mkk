define('films/IndexPage/IndexPage', [
	'fir/controls/FirControl',
	'css!films/IndexPage/IndexPage'
], function(FirControl) {
return FirClass(
	function IndexPage(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});