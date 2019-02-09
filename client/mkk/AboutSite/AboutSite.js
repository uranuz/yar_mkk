define('mkk/AboutSite/AboutSite', [
	'fir/controls/FirControl',
	'css!mkk/AboutSite/AboutSite'
], function (FirControl) {
return FirClass(
	function AboutSite(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});