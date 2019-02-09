define('mkk/Pohod/Read/Read', [
	'fir/controls/FirControl',
	'fir/datctrl/helpers',
	'mkk/Tourist/NavigatedList/NavigatedList',
	'mkk/Helpers/EntityProperty/EntityProperty',
	'css!mkk/Pohod/Read/Read'
], function(FirControl, DatctrlHelpers) {
	__extends(PohodRead, FirControl);

	//Инициализация блока редактирования похода
	function PohodRead(opts)
	{	
		FirControl.call(this, opts);
		var self = this;

		this._partyRS = DatctrlHelpers.fromJSON(opts.partyList); // RecordSet с участниками похода
		this._partyListProp = this.getChildInstanceByName('partyListProp');
		this._partyList = this._partyListProp.getChildInstanceByName('partyList');
		this._partyList.setFilter({
			selectedKeys: this.getPartyNums()
		});
	}
	return __mixinProto(PohodRead, {
		/** Получить идентификаторы участников группы */
		getPartyNums: function() {
			var selectedKeys = [], rec;
			for( this._partyRS.rewind(); rec = this._partyRS.next(); ) {
				selectedKeys.push( rec.getKey() );
			}
			return selectedKeys;
		}
	});
});