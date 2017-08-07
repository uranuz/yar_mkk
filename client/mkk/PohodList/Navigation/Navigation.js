define('mkk/PohodList/Navigation/Navigation', [
	'fir/controls/FirControl'
], function(FirControl) {
	__extends(PohodListNavigation, FirControl);

	function PohodListNavigation(opts) {
		FirControl.call(this, opts);

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