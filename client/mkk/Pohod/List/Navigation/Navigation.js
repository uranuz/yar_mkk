define('mkk/Pohod/List/Navigation/Navigation', [
	'fir/controls/FirControl',
	'fir/controls/Pagination/Pagination',
	'css!mkk/Pohod/List/Navigation/Navigation'
], function(FirControl) {
return FirClass(
	function PohodListNavigation(opts) {
		this.superproto.constructor.call(this, opts);
		var self = this;

		this._elems().filter(".e-print_page_btn")
			.on("click", this.onPrintPageBtnClick.bind(this));
	}, FirControl, {
		onPrintPageBtnClick: function () {
			this._elems().filter(".e-for_print_input").val("on");
			this._elems().filter(".e-form")[0].submit();
		}
	}
);
});