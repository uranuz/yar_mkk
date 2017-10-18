define('mkk/IndexPage/IndexPage', [
	'fir/controls/FirControl',
	'css!mkk/IndexPage/IndexPage'
], function(FirControl) {
	__extends(IndexPage, FirControl);

	function IndexPage(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(IndexPage, {});
});