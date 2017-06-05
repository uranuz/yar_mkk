define('mkk/Pagination/Pagination', [
	'fir/controls/FirControl'
], function(FirControl) {
	__extends(Pagination, FirControl);

	function Pagination(opts) {
		opts = opts || {};
		FirControl.call(this, opts);
		this.formField = opts.formField;
		this._elems("prevBtn").on("click", this.gotoPrev.bind(this));
		this._elems("nextBtn").on("click", this.gotoNext.bind(this));
		this._elems("gotoPageBtn").on("click", this.gotoPage.bind(this));
	}

	return __mixinProto(Pagination, {
		gotoPrev: function() {
			this._setPage(+this._elems("currentPageField").val() - 1);
		},
		gotoNext: function() {
			this._setPage(+this._elems("currentPageField").val() + 1);
		},
		gotoPage: function() {
			this._setPage(+this._elems("currentPageField").val());
		},
		_setPage: function(pageNum) {
			var closestForm = this._container.closest("form");
			this._notify('onSetPage', pageNum);
			if( this.formField && closestForm.length ) {
				this._elems("currentPageField").val(pageNum);
				closestForm[0].submit();
			}
		}
	});
});