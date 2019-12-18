define('mkk/IndexPage/IndexPage', [
	'fir/controls/FirControl',
	'mkk/AboutSite/AboutSite',
	'mkk/IndexPage/IndexPage.scss'
], function(FirControl) {
return FirClass(
	function IndexPage(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});