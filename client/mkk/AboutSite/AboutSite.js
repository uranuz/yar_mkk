define('mkk/AboutSite/AboutSite', [
	'fir/controls/FirControl',
	'mkk/AboutSite/AboutSite.scss'
], function (FirControl) {
return FirClass(
	function AboutSite(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});