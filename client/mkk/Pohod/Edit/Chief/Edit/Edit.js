define('mkk/Pohod/Edit/Chief/Edit/Edit', [
	'fir/controls/FirControl',
	'mkk/Tourist/SearchArea/SearchArea'
], function (FirControl) {
return FirClass(
	function ChiefEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._searchBlock.subscribe('itemSelect', this._onSelectChief.bind(this));

			this._elems("deleteBtn").on("click", this._onDeleteChief.bind(this));
			this._getContainer().on("dialogclose", this._onDialogClose.bind(this));
		});

		this._unsubscr(function() {
			this._searchBlock.unsubscribe('itemSelect');
			this._elems("deleteBtn").off('click');
			this._getContainer().off('dialogclose');
		});

		this._searchBlock = this.getChildByName(this.instanceName() + 'SearchArea');
		this._controlBar = this._elems('controlBar');
	}, FirControl, {
		//"Тык" по кнопке выбора руководителя или зама похода
		_onSelectChief: function(ev, rec) {
			this._chiefRec = rec;
			this._notify("selectChief", rec, this._isAltChief);
			this.closeDialog();
		},

		//Тык по кнопке удаления зам. руководителя похода
		_onDeleteChief: function(ev) {
			var rec = this._chiefRec;
			this._chiefRec = null;
			this._notify("deleteChief", rec, this._isAltChief);
			this.closeDialog();
		},

		openDialog: function(record, isAltChief) {
			var dlgTitle = "";
			this.chiefRec = record;
			if( isAltChief != null ) {
				this._isAltChief = isAltChief;
			}
			if( isAltChief ) {
				this._controlBar.show();
				dlgTitle = 'Выбор зам. руководителя';
			} else {
				this._controlBar.hide();
				dlgTitle = 'Выбор руководителя';
			}
			this._searchBlock.activate(this._elems("searchBlock"));
			this._getContainer().dialog({modal: true, minWidth: 500, title: dlgTitle});
		},

		closeDialog: function() {
			this._getContainer().dialog('close');
		},

		_onDialogClose: function() {
			this._searchBlock.deactivate();
		}
	});
});