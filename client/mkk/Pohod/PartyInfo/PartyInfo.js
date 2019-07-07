define('mkk/Pohod/PartyInfo/PartyInfo', [
	'fir/controls/FirControl',
	'mkk/Tourist/PlainList/PlainList'
], function(FirControl) {
return FirClass(
	function PartyInfo(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});