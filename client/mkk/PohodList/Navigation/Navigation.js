define('mkk/PohodList/Navigation/Navigation', [
	'fir/controls/ITEMControl'
], function(ITEMControl) {
	__extends(PohodListNavigation, ITEMControl);

	function PohodListNavigation(opts) {
		opts = opts || {};
		opts.controlTypeName = 'mkk_site.PohodListNavigation';
		_super.call(this, opts);

		this._elems().filter(".e-print_page_btn")
			.on("click", this.onPrintPageBtnClick.bind(this));
	}

	return __mixinProto(PohodListNavigation, {
		onPrintPageBtnClick: function () {
			this._elems().filter(".e-for_print_input").val("on");
			this._elems().filter(".e-form")[0].submit();
		}
	});
});