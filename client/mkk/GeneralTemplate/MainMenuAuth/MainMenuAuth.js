define('mkk/GeneralTemplate/MainMenuAuth/MainMenuAuth', [
	'fir/controls/FirControl',
	'css!mkk/GeneralTemplate/MainMenuAuth/MainMenuAuth'
], function(FirControl) {
	__extends(MainMenuAuth, FirControl);

	function MainMenuAuth(opts) {
		FirControl.call(this, opts);

		var popdownBtn = this._elems('popdownBtn');

		this._outsideClickHdlInstance = this.addOutsideClickHandler.bind(this);
		popdownBtn.on('click', this.onPopdownBtnClick.bind(this));
	}

	return __mixinProto(MainMenuAuth, {
		onPopdownBtnClick: function(ev) {
			var popdownMenu = this._elems('popdownMenu');
			if( popdownMenu.is(':visible') ) {
				$('html').off('click', this._outsideClickHdlInstance);
			} else {
				$('html').on('click', this._outsideClickHdlInstance);
			}
			popdownMenu.toggle();
		},
		addOutsideClickHandler: function(ev) {
			var
				block = this._elems('block'),
				popdownMenu = this._elems('popdownMenu'),
				popdownBtn = this._elems('popdownBtn');
			if( !$(ev.target).closest(block).length ) {
				$('html').off('click', this._outsideClickHdlInstance);
				popdownMenu.hide();
			}
		}
	});
});