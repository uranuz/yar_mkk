define('mkk/Pagination/Pagination', [
	'fir/controls/FirControl'
], function(FirControl) {
	__extends(Pagination, FirControl);

	function Pagination(opts) {
		opts = opts || {};
		FirControl.call(this, opts);
	}

	return __mixinProto(Pagination, {

	});
});