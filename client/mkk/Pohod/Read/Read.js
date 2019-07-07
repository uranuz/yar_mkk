define('mkk/Pohod/Read/Read', [
	'fir/controls/FirControl',
	'mkk/Tourist/NavList/NavList',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/Pohod/Read/Read'
], function(FirControl) {
'use strict';
return FirClass(
	function PohodRead(opts) {
		this.superproto.constructor.call(this, opts);
		this._partyListProp = this.getChildByName('partyListProp');
		this._partyListProp
			.getChildByName('partyList')
			.setFilterGetter(this.getPartyListFilter.bind(this));
	}, FirControl, {
		getPartyListFilter: function() {
			return {
				nums: this._partyList.getKeys()
			};
		}
	}
);
});