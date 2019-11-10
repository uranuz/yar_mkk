define('films/IndexPage/IndexPage', [
	'fir/controls/FirControl',
	'films/IndexPage/IndexPage.scss'
], function(FirControl) {
return FirClass(
	function IndexPage(opts) {
		this.superproto.constructor.call(this, opts);
	}, FirControl
);
});