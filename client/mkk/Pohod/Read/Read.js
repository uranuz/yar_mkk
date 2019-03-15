define('mkk/Pohod/Read/Read', [
	'fir/controls/FirControl',
	'fir/datctrl/helpers',
	'mkk/Tourist/NavigatedList/NavigatedList',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/Pohod/Read/Read'
], function(FirControl, DatctrlHelpers) {
return FirClass(
	//Инициализация блока редактирования похода
	function PohodRead(opts) {
		this.superproto.constructor.call(this, opts);
		var self = this;

		this._partyRS = DatctrlHelpers.fromJSON(opts.partyList); // RecordSet с участниками похода
		this._partyListProp = this.getChildByName('partyListProp');
		this._partyList = this._partyListProp.getChildByName('partyList');
		this._partyList.setFilter({
			selectedKeys: this.getPartyNums()
		});
	}, FirControl, {
		/** Получить идентификаторы участников группы */
		getPartyNums: function() {
			return this._partyRS.getKeys();
		}
	}
);
});