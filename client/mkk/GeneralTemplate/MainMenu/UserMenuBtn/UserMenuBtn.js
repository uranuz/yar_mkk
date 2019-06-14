define('mkk/GeneralTemplate/MainMenu/UserMenuBtn/UserMenuBtn', [
	'fir/controls/FirControl',
	'css!mkk/GeneralTemplate/MainMenu/UserMenuBtn/UserMenuBtn'
], function(FirControl) {
return FirClass(
	function UserMenuBtn(opts) {
		this.superproto.constructor.call(this, opts);

		this._outsideClickHdlInstance = this.addOutsideClickHandler.bind(this);
		this._elems('popdownBtn').on('click', this.onPopdownBtnClick.bind(this));
	}, FirControl, {
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
				popdownMenu = this._elems('popdownMenu');
			if( !$(ev.target).closest(block).length ) {
				$('html').off('click', this._outsideClickHdlInstance);
				popdownMenu.hide();
			}
		}
	});
});