define('mkk/RecordHistory/RecordHistory', [
	'fir/controls/FirControl',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/RecordHistory/RecordHistory'
], function (
	FirControl
) {
	__extends(RecordHistory, FirControl);

	//Инициализация блока редактирования похода
	function RecordHistory(opts)
	{
		FirControl.call(this, opts);
		this._elems('dataSpoilerBtn').on('click', this._onSpoilerToggle.bind(this))
	}
	return __mixinProto(RecordHistory, {
		_onSpoilerToggle: function(ev) {
			$(ev.target).closest('.e-dataSpoilerBlock').find('.e-dataSpoiler').toggle();
			$(ev.target).toggleClass('is-open');
		}
	});
});