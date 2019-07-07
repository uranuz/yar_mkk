define('mkk/Tourist/Similar/Similar', [
	'fir/controls/FirControl',
	'css!mkk/Tourist/Similar/Similar'
], function (FirControl, FirHelpers) {
return FirClass(
	function TouristSimilar(opts) {
		this.superctor(TouristSimilar, opts);
		this._subscr(function() {
			this._elems('forceSubmitBtn').on('click', this._onForceSubmitBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('forceSubmitBtn').off('click');
		});
	}, FirControl, {
		_onForceSubmitBtn_click: function() {
			this._notify('onForceSubmit');
			this.destroy();
		}
	});
});