define('mkk/Experience/Experience', [
	'fir/controls/FirControl',
	'css!mkk/Experience/Experience'
], function (FirControl) {
	__extends(Experience, FirControl);

	function Experience(opts) {
		opts = opts || {};
		FirControl.call(this, opts);
	}
	return __mixinProto(Experience, {});
});