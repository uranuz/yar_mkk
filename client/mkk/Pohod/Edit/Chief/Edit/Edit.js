define('mkk/Pohod/Edit/Chief/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/Tourist/SearchArea/SearchArea'
], function (FirControl) {
return FirClass(
	function ChiefEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this.getChildByName(this.instanceName() + 'SearchArea')
			.subscribe('itemSelect', this._onSelectChief.bind(this));

		this._subscr(function() {
			this._elems("deleteBtn").on("click", this._onDeleteChief.bind(this));
		});

		this._unsubscr(function() {
			this._elems("deleteBtn").off('click');
		});
	}, FirControl, {
		//"Тык" по кнопке выбора руководителя или зама похода
		_onSelectChief: function(ev, rec) {
			this._chiefRec = rec;
			this._notify("selectChief", rec, this._isAltChief);
		},

		//Тык по кнопке удаления зам. руководителя похода
		_onDeleteChief: function(ev) {
			var rec = this._chiefRec;
			this._chiefRec = null;
			this._notify("deleteChief", rec, this._isAltChief);
		}
	});
});