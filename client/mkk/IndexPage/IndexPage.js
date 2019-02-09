define('mkk/IndexPage/IndexPage', [
	'fir/controls/FirControl',
	'css!mkk/IndexPage/IndexPage'
], function(FirControl) {
return FirClass(
	function IndexPage(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});