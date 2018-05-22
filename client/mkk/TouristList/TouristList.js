define('mkk/TouristList/TouristList', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'css!mkk/TouristList/TouristList'
], function (FirControl, DatctrlHelpers) {
	__extends(TouristList, FirControl);

	function TouristList(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(TouristList, {});
});