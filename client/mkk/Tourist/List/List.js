define('mkk/Tourist/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'css!mkk/Tourist/List/List'
], function (FirControl) {
return FirClass(
	function TouristList(opts) {
		FirControl.call(this, opts);
	}, FirControl
);
});