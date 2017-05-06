var mkk_site = mkk_site || {
	version: "0.0"
};


mkk_site.MainMenuAuth = (function(_super) {
	__extends(MainMenuAuth, _super);

	function MainMenuAuth(opts)
	{
		opts = opts || {};
		opts.controlTypeName = 'MainMenuAuth';
		_super.call(this, opts);
		var
			popdownBtn = this._elems().filter('.e-popdown_btn');

		this._outsideClickHdlInstance = this.addOutsideClickHandler.bind(this);
		popdownBtn.on( 'click', this.onPopdownBtnClick.bind(this) );
	}

	return __mixinProto(MainMenuAuth, {
		onPopdownBtnClick: function(ev) {
			var
				elems = this._elems(),
				popdownMenu = elems.filter('.e-popdown_menu');

				if( popdownMenu.is(':visible') ) {
					$('html').off( 'click', this._outsideClickHdlInstance );
				} else {
					$('html').on( 'click', this._outsideClickHdlInstance );
				}
				popdownMenu.toggle();
		},
		addOutsideClickHandler: function(ev) {
			var
				block = this._elems().filter('.e-block'),
				popdownMenu = this._elems().filter('.e-popdown_menu'),
				popdownBtn = this._elems().filter('.e-popdown_btn');
			if( !$(ev.target).closest(block).length ) {
					$('html').off( 'click', this._outsideClickHdlInstance );
					popdownMenu.hide();
			}
		}
	});
})(webtank.ITEMControl);

mkk_site.Pagination = (function(_super) {
	__extends(Pagination, _super);
	
	function Pagination(opts)
	{
		opts = opts || {};
		_super.call(this, opts);

		this._form = opts.form;

		this._prevBtn = this._elems().filter('.e-prev_btn')
			.on( 'click', this.gotoPrev.bind(this) );
		this._nextBtn = this._elems().filter('.e-next_btn')
			.on( 'click', this.gotoNext.bind(this) );
		this._gotoPageBtn = this._elems().filter('.e-goto_page_btn')
			.on( 'click', this.gotoPage.bind(this) );
		this._pageNumInput = this._elems().filter('.e-page_num_input');

		this._currPageNum = +this._pageNumInput.val() || 1;
	}
	
	return __mixinProto(Pagination, {
		gotoPrev: function() {
			this._pageNumInput.val( this._currPageNum - 1 );
			this.gotoPage();
		},
		gotoNext: function() {
			this._pageNumInput.val( this._currPageNum + 1 );
			this.gotoPage();
		},
		gotoPage: function() {
			this._form[0].submit();
		}
	});
})(webtank.ITEMControl);
