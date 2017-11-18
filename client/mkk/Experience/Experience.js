define('mkk/Experience/Experience', [
	'fir/controls/FirControl',
	'mkk/Pagination/Pagination',
	'css!mkk/Experience/Experience'
], function (FirControl) {
	__extends(Experience, FirControl);

	function Experience(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(Experience, {});
});