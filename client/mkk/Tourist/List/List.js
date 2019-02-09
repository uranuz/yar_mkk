define('mkk/Tourist/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'css!mkk/Tourist/List/List'
], function (FirControl, DatctrlHelpers) {
	__extends(TouristList, FirControl);

	function TouristList(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(TouristList, {});
});