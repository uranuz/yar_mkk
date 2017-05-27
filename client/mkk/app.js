require.config({
	waitSeconds: 120,
	baseUrl: "/pub"
});

require([
	'fir/controls/FirControl'
], function(FirControl) {
	FirControl.prototype.initAllControls();
});