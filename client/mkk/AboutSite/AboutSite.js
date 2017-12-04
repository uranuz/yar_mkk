define('mkk/AboutSite/AboutSite', [
	'fir/controls/FirControl',
	'css!mkk/AboutSite/AboutSite'
], function (FirControl) {
	__extends(AboutSite, FirControl);

	function AboutSite(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(AboutSite, {});
});