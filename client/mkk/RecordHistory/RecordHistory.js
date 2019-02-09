define('mkk/RecordHistory/RecordHistory', [
	'fir/controls/FirControl',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/RecordHistory/RecordHistory'
], function (FirControl) {
return FirClass(
	function RecordHistory(opts) {
		this.superproto.constructor.call(this, opts);
		this._elems('dataSpoilerBtn').on('click', this._onSpoilerToggle.bind(this))
	}, FirControl, {
		_onSpoilerToggle: function(ev) {
			$(ev.target).closest('.e-dataSpoilerBlock').find('.e-dataSpoiler').toggle();
			$(ev.target).toggleClass('is-open');
		}
	});
});