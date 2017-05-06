require.config({
	baseUrl: "/pub"
});

require([
	'fir/controls/FirControl'
], function(FirControl) {
	FirControl.prototype.initAllControls();
});