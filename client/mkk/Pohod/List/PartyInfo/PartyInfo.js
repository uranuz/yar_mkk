define('mkk/Pohod/List/PartyInfo/PartyInfo', [
	'fir/controls/FirControl',
	'mkk/Tourist/PlainList/PlainList'
], function(FirControl, DialogMixin) {
return FirClass(
	function PartyInfo(opts) {
		this.superproto.constructor.call(this, opts);
		this._num = null;
	}, FirControl, {
		_getRequestURI: function() {
			return '/dyn/pohod/partyInfo';
		},
		setNum: function(num) {
			this._num = num;
		},
		_getQueryParams: function() {
			return {
				num: this._num,
				generalTemplate: 'no'
			};
		}
	}
);
});