define('mkk/TouristList/TouristList', [
	'fir/controls/FirControl',
	'mkk/Pagination/Pagination',
	'css!mkk/TouristList/TouristList'
], function (FirControl, DatctrlHelpers) {
	__extends(TouristList, FirControl);

	function TouristList(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(TouristList, {});
});